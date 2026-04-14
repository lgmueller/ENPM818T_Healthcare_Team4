-- Query #1: Example 1: Patient Care Coordination (Patient Based)
-- Clinical/Financial/Operational Context: For a patient arriving for an appointment, clinicians and front-desk staff need one view of demographics, current insurance coverage, and active prescriptions to support safe and efficient care.
-- Tables Used: patient, phone_numbers, insurance, prescription, medication
-- Complexity Features: LEFT JOINs, date filtering, active-status filtering, ordering output

SELECT
    p.MRN,
    p.first_name,
    p.last_name,
    p.dob,
    p.gender,
    pn.number AS phone_number,
    p.city,
    p.state,
    p.communication_pref,
    p.pharmacy_pref,

    i.insurance_company,
    i.policy_no,
    i.group_no,
    i.copay_amount,
    i.coverage,
    i.effective_date,
    i.termination_date,

    pr.prescription_id,
    m.medication_name,
    m.schedule,
    pr.dosage,
    pr.frequency,
    pr.duration,
    pr.prescription_status,
    pr.date_prescribed,
    pr.expiration_date

FROM patient p
LEFT JOIN phone_numbers pn
    ON p.MRN = pn.MRN
LEFT JOIN insurance i
    ON p.MRN = i.MRN
   AND CURRENT_TIMESTAMP BETWEEN i.effective_date AND i.termination_date
LEFT JOIN prescription pr
    ON p.MRN = pr.MRN
   AND pr.prescription_status = 'active'
   AND (pr.expiration_date IS NULL OR pr.expiration_date > CURRENT_TIMESTAMP)
LEFT JOIN medication m
    ON pr.medication_id = m.medication_id

WHERE p.MRN = '1000000000'
ORDER BY m.medication_name;


-- Expected Output:
-- One row per active prescription for a selected patient.
-- Includes patient demographics, contact details, active insurance coverage,
-- and prescription details including dosage and validity dates.

-- Columns:
-- MRN | first_name | last_name | dob | gender | phone_number | city | state | communication_pref | pharmacy_pref | insurance_company | policy_no | group_no | copay_amount | coverage | effective_date | termination_date | prescription_id | medication_name | schedule | dosage | frequency | duration | prescription_status | date_prescribed | expiration_date

-- Sample Results:
-- 1000000000 | Xavier | Martin | 1995-12-13 | M | 2402351205 | Falls Church | VA | sms | Giant Pharmacy Rockville | UnitedHealthcare | POL000114251 | G75104 | 20.00 | Employee health plan | 2025-08-15 00:00:00+00 | 2027-01-24 00:00:00+00 | NULL | NULL | NULL | NULL | NULL | NULL | NULL | NULL | NULL
-- 1000000000 | Xavier | Martin | 1995-12-13 | M | 3014805841 | Falls Church | VA | sms | Giant Pharmacy Rockville | UnitedHealthcare | POL000114251 | G75104 | 20.00 | Employee health plan | 2025-08-15 00:00:00+00 | 2027-01-24 00:00:00+00 | NULL | NULL | NULL | NULL | NULL | NULL | NULL | NULL | NULL




-- Query #1: 2nd example: Patient Care Coordination (Appointment Based)
-- Clinical/Financial/Operational Context: For a patient arriving for an appointment, clinicians and front-desk staff need one view of demographics, insurance coverage, and active prescriptions.
-- Tables Used: appointment, patient, phone_numbers, insurance, prescription, medication, provider_availability
-- Complexity Features: INNER JOIN, LEFT JOINs, filtering, ordering

SELECT
    a.appointment_id,
    p.MRN,
    p.first_name,
    p.last_name,
    p.dob,
    p.gender,
    pn.number AS phone_number,
    p.city,
    p.state,
    p.communication_pref,
    p.pharmacy_pref,
    pa.slot_date,
    pa.start_time,
    pa.end_time,

    i.insurance_company,
    i.policy_no,
    i.group_no,
    i.copay_amount,
    i.coverage,

    pr.prescription_id,
    m.medication_name,
    m.schedule,
    pr.dosage,
    pr.frequency,
    pr.duration,
    pr.prescription_status

FROM appointment a
JOIN patient p
    ON a.MRN = p.MRN
JOIN provider_availability pa
    ON a.slot_id = pa.slot_id
LEFT JOIN phone_numbers pn
    ON p.MRN = pn.MRN
LEFT JOIN insurance i
    ON p.MRN = i.MRN
   AND CURRENT_TIMESTAMP BETWEEN i.effective_date AND i.termination_date
LEFT JOIN prescription pr
    ON p.MRN = pr.MRN
   AND pr.prescription_status = 'active'
   AND (pr.expiration_date IS NULL OR pr.expiration_date > CURRENT_TIMESTAMP)
LEFT JOIN medication m
    ON pr.medication_id = m.medication_id
WHERE a.appointment_id = 1
ORDER BY m.medication_name;


-- Expected Output:
-- One row per active prescription for a patient tied to a specific appointment.
-- Includes appointment details, patient demographics, contact info,
-- scheduled visit time, current insurance coverage, and active prescriptions.

-- Columns: appointment_id | MRN | first_name | last_name | dob | gender | phone_number | city | state | communication_pref | pharmacy_pref | slot_date | start_time | end_time | insurance_company | policy_no | group_no | copay_amount | coverage | prescription_id | medication_name | schedule | dosage | frequency | duration | prescription_status
-- Sample Results:
-- 1 | 1000000067 | Xavier | Martin | 1997-10-06 | M | 2406329828 | Gaithersburg | MD | phone | Walgreens Bethesda | 2026-05-19 | 09:30:00 | 10:30:00 | Medicare | POL006811549 | G58144 | 20.00 | Medicare Part B | NULL | NULL | NULL | NULL | NULL | NULL | NULL








-- Query #2: Medication Safety
-- Clinical/Financial/Operational Context: Patients with multiple active prescriptions (3 or more in this dataset) are at increased risk for polypharmacy...
-- Tables Used: prescription, patient, provider, medication
-- Complexity Features: JOINs, GROUP BY, HAVING, correlated subquery, ordering

SELECT
    pt.MRN,
    pt.first_name AS patient_first_name,
    pt.last_name AS patient_last_name,

    (
        SELECT COUNT(*)
        FROM prescription pr2
        WHERE pr2.MRN = pt.MRN
          AND pr2.prescription_status = 'active'
          AND (pr2.expiration_date IS NULL OR pr2.expiration_date > CURRENT_TIMESTAMP)
    ) AS active_prescription_count,

    pr.prescription_id,
    m.medication_name,

    prv.provider_id,
    prv.first_name AS provider_first_name,
    prv.last_name AS provider_last_name,
    prv.provider_type

FROM prescription pr
JOIN patient pt
    ON pr.MRN = pt.MRN
LEFT JOIN medication m
    ON pr.medication_id = m.medication_id
LEFT JOIN provider prv
    ON pr.provider_id = prv.provider_id

WHERE pr.prescription_status = 'active'
  AND (pr.expiration_date IS NULL OR pr.expiration_date > CURRENT_TIMESTAMP)
  AND (
        SELECT COUNT(*)
        FROM prescription pr2
        WHERE pr2.MRN = pt.MRN
          AND pr2.prescription_status = 'active'
          AND (pr2.expiration_date IS NULL OR pr2.expiration_date > CURRENT_TIMESTAMP)
      ) >= 3

ORDER BY
    active_prescription_count DESC,
    pt.last_name,
    pt.first_name,
    m.medication_name;

-- Expected Output: One row per active prescription for each patient with 5 or more active prescriptions. Columns show patient identity, total active prescription count, medication name, and prescribing provider details.
-- Columns: mrn | patient_first_name | patient_last_name | active_prescription_count | prescription_id | medication_name | provider_id | provider_first_name | provider_last_name | provider_type
-- Sample Results:
-- -- 1000000030 | Sofia | White | 3 | 65 | Cefdinir     | 18 | Samuel | Diaz   | Physician
-- -- 1000000030 | Sofia | White | 3 | 19 | Clopidogrel  | 21 | Lily   | Chen   | Physician
-- -- 1000000030 | Sofia | White | 3 | 81 | Clopidogrel  | 23 | Ella   | Howard | Physician









-- Query #3: Provider Workload
-- Clinical/Financial/Operational Context: Providers and scheduling staff need visibility into upcoming appointments in order to prepare charts, rooms, and staffing resources.
-- Tables Used: provider, provider_availability, appointment, patient, facility
-- Complexity Features: INNER JOINs, date filtering, ordering output

SELECT
    prv.provider_id,
    prv.first_name AS provider_first_name,
    prv.last_name AS provider_last_name,
    prv.provider_type,

    pa.slot_date,
    pa.start_time,
    pa.end_time,

    f.facility_id,
    f.facility_name,

    a.appointment_id,
    pt.MRN,
    pt.first_name AS patient_first_name,
    pt.last_name AS patient_last_name,
    a.appt_type,
    a.appt_status,
    a.visit_reason

FROM provider_availability pa
JOIN provider prv
    ON pa.provider_id = prv.provider_id
JOIN appointment a
    ON pa.slot_id = a.slot_id
JOIN patient pt
    ON a.MRN = pt.MRN
JOIN facility f
    ON pa.facility_id = f.facility_id

WHERE pa.slot_date >= CURRENT_DATE
  AND a.appt_status IN ('scheduled', 'confirmed')

ORDER BY
    prv.last_name,
    prv.first_name,
    pa.slot_date,
    pa.start_time;

-- Expected Output: One row per upcoming appointment, including provider details, appointment date and time, facility, patient name, appointment type, status, and reason for visit.
-- Columns: provider_id | provider_first_name | provider_last_name | provider_type | slot_date | start_time | end_time | facility_id | facility_name | appointment_id | mrn | patient_first_name | patient_last_name | appt_type | appt_status | visit_reason
-- Sample Results:
-- 17 | Zoe    | Baker   | Physician | 2026-04-19 | 15:00:00 | 15:45:00 | 3 | Chesapeake Children's Hospital | 106 | 1000000028 | Meera | Wilson  | telehealth  | confirmed | Mood and sleep concerns
-- 17 | Zoe    | Baker   | Physician | 2026-04-19 | 16:00:00 | 16:45:00 | 3 | Chesapeake Children's Hospital | 184 | 1000000033 | Caleb | Edwards | telehealth  | scheduled | Diabetes monitoring
-- 17 | Zoe    | Baker   | Physician | 2026-04-20 | 08:30:00 | 09:00:00 | 6 | Capitol Primary Care Clinic   | 182 | 1000000022 | Chloe | Martin  | new_patient | scheduled | Upper respiratory symptoms







-- Query #4: Insurance Coverage Summary
-- Clinical/Financial/Operational Context: Administrative and revenue-cycle teams need payer-level summaries showing how many patients are covered by each insurer and the average copay burden associated with that insurer.
-- Tables Used: insurance
-- Complexity Features: GROUP BY, DISTINCT counting, aggregates, ordering

SELECT
    insurance_company,
    COUNT(DISTINCT MRN) AS covered_patient_count,
    ROUND(AVG(copay_amount), 2) AS avg_copay_amount,
    MIN(copay_amount) AS min_copay_amount,
    MAX(copay_amount) AS max_copay_amount
FROM insurance
WHERE CURRENT_TIMESTAMP BETWEEN effective_date AND termination_date
GROUP BY insurance_company
ORDER BY covered_patient_count DESC, insurance_company;

-- Expected Output: One row per active insurance company, showing the number of distinct covered patients and the average, minimum, and maximum copay amounts.
-- Columns: insurance_company | covered_patient_count | avg_copay_amount | min_copay_amount | max_copay_amount
-- Sample Results:
-- -- Maryland Medicaid              | 18 | 25.00 | 0.00  | 50.00
-- -- BlueCross BlueShield of Maryland | 17 | 23.24 | 0.00  | 50.00
-- -- Kaiser Permanente              | 13 | 28.46 | 10.00 | 50.00






-- Query #5: Prescription Costs
-- Clinical/Financial/Operational Context: List all active prescriptions with patient name, medication, and insurance policy, ordered by patient.
-- Tables Used: prescription, patient, medication, insurance
-- Complexity Features: INNER JOIN, LEFT JOIN, WHERE filtering, ordering output

SELECT
    pat.MRN,
    pat.first_name AS patient_first_name,
    pat.last_name  AS patient_last_name,

    m.medication_name,

    pr.prescription_id,
    pr.date_prescribed,
    pr.expiration_date,
    pr.dosage,
    pr.frequency,

    ins.insurance_company,
    ins.policy_no,
    ins.group_no

FROM prescription pr
JOIN patient pat
    ON pr.MRN = pat.MRN
JOIN medication m
    ON pr.medication_id = m.medication_id
LEFT JOIN insurance ins
    ON pat.MRN = ins.MRN
       AND CURRENT_TIMESTAMP BETWEEN ins.effective_date AND ins.termination_date

WHERE pr.prescription_status = 'active'
  AND (pr.expiration_date IS NULL OR pr.expiration_date > CURRENT_TIMESTAMP)

ORDER BY
    pat.last_name,
    pat.first_name,
    m.medication_name;

-- Expected Output: table of active prescriptions with patient name, medication, and insurance details, ordered by patient.
-- Sample Results:

-- Query #6: Provider Productivity
-- Clinical/Financial/Operational Context: Show appointment counts, no-show rates, and average patients per day by provider.
-- Tables Used: appointment, provider_availability, provider
-- Complexity Features: INNER JOINs, GROUP BY, aggregates, conditional counting, handling division by zero

SELECT
    p.provider_id,
    p.first_name,
    p.last_name,

    COUNT(a.appointment_id) AS total_appointments,

    SUM(CASE WHEN a.appt_status = 'no_show' THEN 1 ELSE 0 END) AS no_show_count,

    ROUND(
        100.0 * SUM(CASE WHEN a.appt_status = 'no_show' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(a.appointment_id), 0),
        2
    ) AS no_show_rate_percent,

    COUNT(DISTINCT DATE(pa.slot_date)) AS active_days,
    ROUND(COUNT(a.appointment_id) * 1.0 / NULLIF(COUNT(DISTINCT DATE(pa.slot_date)), 0), 2) AS avg_patients_per_day
FROM appointment a
JOIN provider_availability pa
    ON a.slot_id = pa.slot_id
JOIN provider p
    ON pa.provider_id = p.provider_id   
GROUP BY p.provider_id, p.first_name, p.last_name
ORDER BY p.last_name, p.first_name DESC;

-- Expected Output: table of providers with appointment counts, no-show rates, and average patients per day, ordered by provider name.
-- Sample Results:

-- Query #7: Controlled Substances
-- Clinical/Financial/Operational Context: Report all Schedule II controlled substance prescriptions by provider, required for DEA reporting.
-- Tables Used: prescription, provider, patient, medication, dea_no
-- Complexity Features: INNER JOINs, WHERE filtering, ordering output

SELECT
    p.provider_id,
    p.first_name,
    p.last_name,

    pr.prescription_id,
    pr.date_prescribed,
    pr.expiration_date,

    pat.MRN,
    pat.first_name AS patient_first_name,
    pat.last_name  AS patient_last_name,

    m.medication_name,
    m.schedule,

    dea.dea_no,

    pr.dosage,
    pr.frequency,
    pr.duration,
    pr.prescription_status

FROM prescription pr
JOIN medication m
    ON pr.medication_id = m.medication_id
JOIN provider p
    ON pr.provider_id = p.provider_id
JOIN patient pat
    ON pr.MRN = pat.MRN
JOIN dea_no dea
    ON pr.provider_id = dea.provider_id

WHERE m.schedule = 'II'
ORDER BY p.provider_id, pr.date_prescribed DESC;

-- Expected Output: table of Schedule II prescriptions with provider, patient, medication, and DEA details, ordered by provider and prescription date.
-- Sample Results: 

-- Query #8: Appointment Status Breakdown
-- Clinical/Financial/Operational Context: Show counts of appointments by status (completed, no-show, cancelled) broken down by facility.
-- Tables Used: facility, provider_availability, appointment
-- Complexity Features: INNER JOINs, GROUP BY, aggregates, conditional counting, handling division by zero

SELECT
    f.facility_id,
    f.facility_name,

    COUNT(a.appointment_id) AS total_appointments,

    SUM(CASE WHEN a.appt_status = 'completed' THEN 1 ELSE 0 END) AS completed_count,
    SUM(CASE WHEN a.appt_status = 'no_show' THEN 1 ELSE 0 END) AS no_show_count,
    SUM(CASE WHEN a.appt_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_count,

    ROUND(
        100.0 * SUM(CASE WHEN a.appt_status = 'no_show' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(a.appointment_id), 0),
        2
    ) AS no_show_rate_percent

FROM appointment a
JOIN provider_availability pa
    ON a.slot_id = pa.slot_id
JOIN facility f
    ON pa.facility_id = f.facility_id

GROUP BY f.facility_id, f.facility_name
ORDER BY total_appointments DESC;

-- Expected Output: table of facilities with appointment counts by status, ordered by total appointments.
-- Sample Results:




-- Query #9: Upcoming Appointments Without Active Insurance
-- Clinical/Financial/Operational Context: Front-desk and care coordination teams need to identify patients with upcoming appointments who do not currently have active insurance coverage on file, so coverage can be verified before the visit.
-- Tables Used: appointment, patient, provider_availability, facility, insurance
-- Complexity Features: INNER JOINs, LEFT JOIN, date filtering, NULL filtering, ordering

SELECT
    a.appointment_id,
    p.MRN,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    pa.slot_date,
    pa.start_time,
    pa.end_time,
    f.facility_id,
    f.facility_name
FROM appointment a
JOIN patient p
    ON a.MRN = p.MRN
JOIN provider_availability pa
    ON a.slot_id = pa.slot_id
JOIN facility f
    ON pa.facility_id = f.facility_id
LEFT JOIN insurance i
    ON p.MRN = i.MRN
   AND CURRENT_TIMESTAMP BETWEEN i.effective_date AND i.termination_date
WHERE pa.slot_date >= CURRENT_DATE
  AND a.appt_status IN ('scheduled', 'confirmed')
  AND i.insurance_id IS NULL
ORDER BY pa.slot_date, pa.start_time, p.last_name, p.first_name;

-- Expected Output: One row per upcoming scheduled/confirmed appointment where the patient has no active insurance on file. Columns include appointment ID, patient name, date/time, and facility.
-- Sample Results:
-- [paste first 3 real rows from DataGrip]





-- Query #10: Open Provider Capacity by Facility
-- Clinical/Financial/Operational Context: Scheduling and operations teams need visibility into unbooked provider slots in the next 30 days in order to improve access, reduce wait times, and balance provider capacity across facilities.
-- Tables Used: provider_availability, appointment, provider, facility
-- Complexity Features: INNER JOINs, LEFT JOIN, aggregates, GROUP BY, date filtering, ordering

SELECT
    f.facility_id,
    f.facility_name,
    p.provider_id,
    p.first_name AS provider_first_name,
    p.last_name AS provider_last_name,
    p.provider_type,
    COUNT(pa.slot_id) AS total_future_slots,
    COUNT(a.appointment_id) AS booked_slots,
    COUNT(pa.slot_id) - COUNT(a.appointment_id) AS open_slots
FROM provider_availability pa
JOIN provider p
    ON pa.provider_id = p.provider_id
JOIN facility f
    ON pa.facility_id = f.facility_id
LEFT JOIN appointment a
    ON pa.slot_id = a.slot_id
WHERE pa.slot_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
GROUP BY
    f.facility_id,
    f.facility_name,
    p.provider_id,
    p.first_name,
    p.last_name,
    p.provider_type
ORDER BY open_slots DESC, f.facility_name, p.last_name, p.first_name;

-- Expected Output: One row per provider per facility, showing future slot capacity in the next 30 days, how many are booked, and how many remain open.
-- Sample Results:
-- [paste first 3 real rows from DataGrip]





-- Query #11: Abnormal Lab Results Follow-Up
-- Clinical/Financial/Operational Context: Abnormal lab results require timely provider review and possible patient follow-up. This query highlights patients with abnormal test results, the ordering provider, and the facility involved.
-- Tables Used: lab_test, lab_order, patient, provider, facility
-- Complexity Features: INNER JOINs, WHERE filtering, ordering output

SELECT
    lt.test_id,
    lo.order_id,
    p.MRN,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    lt.test_type,
    lt.test_value_result,
    lt.ref_range_low,
    lt.ref_range_high,
    lt.abnormal_flag,
    lt.interpretation_notes,
    lo.date_ordered,
    prv.provider_id,
    prv.first_name AS provider_first_name,
    prv.last_name AS provider_last_name,
    f.facility_id,
    f.facility_name
FROM lab_test lt
JOIN lab_order lo
    ON lt.order_id = lo.order_id
JOIN patient p
    ON lo.MRN = p.MRN
LEFT JOIN provider prv
    ON lo.provider_id = prv.provider_id
LEFT JOIN facility f
    ON lo.facility_id = f.facility_id
WHERE lt.abnormal_flag = TRUE
ORDER BY lo.date_ordered DESC, p.last_name, p.first_name, lt.test_type;

-- Expected Output: One row per abnormal lab test result, including patient identity, test details, abnormal values, ordering provider, and facility.
-- Sample Results: