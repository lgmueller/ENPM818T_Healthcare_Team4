-- Query #1: Example 1: Patient Care Coordination (Patient Based)
-- Clinical Context: For a patient arriving for an appointment, clinicians and front-desk staff need one view of demographics, current insurance coverage, and active prescriptions to support safe and efficient care.
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




-- Query #2: 2nd example: Patient Care Coordination (Appointment Based)
-- Clinical Context: For a patient arriving for an appointment, clinicians and front-desk staff need one view of demographics, insurance coverage, and active prescriptions.
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








-- Query #3: Medication Safety
-- Clinical Context: Patients with multiple active prescriptions (3 or more in this dataset) are at increased risk for polypharmacy...
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









-- Query #4: Provider Workload
-- Clinical Context: Providers and scheduling staff need visibility into upcoming appointments in order to prepare charts, rooms, and staffing resources.
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







-- Query #5: Insurance Coverage Summary
-- Financial Context: Administrative and revenue-cycle teams need payer-level summaries showing how many patients are covered by each insurer and the average copay burden associated with that insurer.
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



-- Query #6: Insurance Claim Summary
-- Financial Context: List all submitted insurance claims with patient name, insurance policy, and total number of submitted claims and charges, ordered by patient.
-- Tables Used: insurance, insurance_claims, patient
-- Complexity Features: GROUP BY, DISTINCT counting, aggregates, ordering

SELECT
    pat.mrn,
    pat.first_name AS patient_first_name,
    pat.last_name AS patient_last_name,

    i.insurance_company,
    i.policy_no,
    i.group_no,

    COUNT(DISTINCT cl.claim_id) AS num_submitted_claims,
    SUM(cl.charge_amount) AS total_charges_amount,
    SUM(cl.patient_responsibility) AS total_responsibility_amount

FROM patient pat
JOIN insurance i
    ON pat.MRN = i.MRN
   AND CURRENT_TIMESTAMP BETWEEN i.effective_date AND i.termination_date
JOIN insurance_claim cl
    ON pat.MRN = cl.MRN
WHERE cl.insurance_claim_status = 'submitted'
GROUP BY pat.mrn, pat.first_name, pat.last_name, i.insurance_company, i.policy_no, i.group_no
ORDER BY pat.last_name, pat.first_name;

-- Expected Output: Table of patients with active insurance coverage and submitted claims, showing patient name, insurance details, and total number of claims and charges, ordered by patient.
-- Columns: insurance_company | covered_patient_count | avg_copay_amount | min_copay_amount | max_copay_amount
-- Sample Results:


-- Query #7: Prescription Costs
-- Financial Context: List all active prescriptions with patient name, medication, and insurance policy, ordered by patient.
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
-- Columns: MRN | patient_first_name | patient_last_name | medication_name | prescription_id | date_prescribed | expiration_date | dosage | frequency | insurance_company | policy_no | group_no

-- Sample Results:
-- 1000000097 | Kai     | Anderson | Rosuvastatin            | 68  | 2026-04-06 17:00:00+00 | 2026-07-05 17:00:00+00 | 10 mg                  | once nightly                     | BlueCross BlueShield of Maryland | POL009811188 | G70587
-- 1000000007 | Victor  | Baker    | Tramadol                | 145 | 2026-03-29 10:45:00+00 | 2026-04-28 10:45:00+00 | 50 mg                  | every 8 hours as needed pain     | Maryland Medicaid                | POL000818967 | G57208
-- 1000000014 | Ariana  | Brown    | Fluticasone nasal spray | 71  | 2026-03-18 10:30:00+00 | 2026-04-17 10:30:00+00 | 2 sprays each nostril  | once daily                       | BlueCross BlueShield of Maryland | POL001515156 | G45256







-- Query #8: Provider Productivity
-- Operational Context: Show appointment counts, no-show rates, and average patients per day by provider.
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
    ROUND(COUNT(a.appointment_id) * 1.0 / NULLIF(COUNT(DISTINCT pa.slot_date), 0), 2) AS avg_patients_per_day
FROM appointment a
JOIN provider_availability pa
    ON a.slot_id = pa.slot_id
JOIN provider p
    ON pa.provider_id = p.provider_id
GROUP BY p.provider_id, p.first_name, p.last_name
ORDER BY p.last_name, p.first_name;

-- Expected Output: table of providers with appointment counts, no-show rates, and average patients per day, ordered by provider name.
-- Columns: provider_id | first_name | last_name | total_appointments | no_show_count | no_show_rate_percent | active_days | avg_patients_per_day

-- Sample Results:
-- 17 | Zoe    | Baker   | 20 | 1 | 5.00  | 19 | 1.05
-- 32 | Jack   | Barnes  | 1  | 0 | 0.00  | 1  | 1.00
-- 1  | Olivia | Bennett | 18 | 0 | 0.00  | 16 | 1.13







-- Query #9: Controlled Substances
-- Operational Context: Report all Schedule II controlled substance prescriptions by provider, required for DEA reporting.
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
-- Columns: provider_id | first_name | last_name | prescription_id | date_prescribed | expiration_date | MRN | patient_first_name | patient_last_name | medication_name | schedule | dea_no | dosage | frequency | duration | prescription_status

-- Sample Results:
-- 15 | Amelia | Brooks | 69 | 2026-03-05 13:00:00+00 | 2026-04-04 13:00:00+00 | 1000000056 | Henry | Hall | Oxycodone | II | SZ8653855 | 5 mg | every 6 hours as needed severe pain | 5 days | discontinued







-- Query #10: Appointment Status Breakdown
-- Operational Context: Show counts of appointments by status (completed, no-show, cancelled) broken down by facility.
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
-- Columns: facility_id | facility_name | total_appointments | completed_count | no_show_count | cancelled_count | no_show_rate_percent

-- Sample Results:
-- 3 | Chesapeake Children's Hospital | 40 | 23 | 6 | 2 | 15.00
-- 4 | District University Hospital   | 35 | 20 | 5 | 3 | 14.29
-- 6 | Capitol Primary Care Clinic    | 29 | 13 | 3 | 4 | 10.34




-- Query #11: Upcoming Appointments Without Active Insurance
-- Operational Context: Front-desk and care coordination teams need to identify patients with upcoming appointments who do not currently have active insurance coverage on file, so coverage can be verified before the visit.
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
-- Columns: appointment_id | MRN | patient_first_name | patient_last_name | slot_date | start_time | end_time | facility_id | facility_name
-- Sample Results:
-- 180 | 1000000044 | Anika | White | 2026-05-03 | 15:00:00 | 15:45:00 | 9 | Laurel Pediatrics Center






-- Query #12: Open Provider Capacity by Facility
-- Operational Context: Scheduling and operations teams need visibility into unbooked provider slots in the next 30 days in order to improve access, reduce wait times, and balance provider capacity across facilities.
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
-- Columns: facility_id | facility_name | provider_id | provider_first_name | provider_last_name | provider_type | total_future_slots | booked_slots | open_slots

-- Sample Results:
-- 8 | Bethesda Internal Medicine       | 1  | Olivia | Bennett | Physician           | 3 | 3 | 0
-- 8 | Bethesda Internal Medicine       | 27 | Harper | Cole    | Physician           | 4 | 4 | 0
-- 8 | Bethesda Internal Medicine       | 5  | Sophia | Patel   | Nurse Practitioner  | 1 | 1 | 0





-- Query #13: Abnormal Lab Results Follow-Up
-- Operational Context: Abnormal lab results require timely provider review and possible patient follow-up. This query highlights patients with abnormal test results, the ordering provider, and the facility involved.
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
-- Columns: test_id | order_id | MRN | patient_first_name | patient_last_name | test_type | test_value_result | ref_range_low | ref_range_high | abnormal_flag | interpretation_notes | date_ordered | provider_id | provider_first_name | provider_last_name | facility_id | facility_name

-- Sample Results:
-- 200 | 88 | 1000000102 | Tessa  | Scott  | CBC          | 11.52 | 12.0 | 17.5 | true | NULL                              | 2026-04-03 17:15:00+00 | 11 | Hannah    | Osei    | 6 | Capitol Primary Care Clinic
-- 176 | 75 | 1000000066 | Lucas  | White  | Lipid panel  | -0.3  | 0    | 149  | true | Critical value called to provider | 2026-03-25 17:45:00+00 | 5  | Sophia    | Patel   | 6 | Capitol Primary Care Clinic
-- 173 | 74 | 1000000087 | Tara   | Parker | CBC          | 123.9 | 150  | 450  | true | NULL                              | 2026-03-20 18:00:00+00 | 23 | Ella      | Howard  | 5 | Memorial General Hospital




-- Query #14: Lab Status Breakdown
-- Operational Context: Show counts of labs orders by priority (routine, urgent, stat) broken down by facility which rates of completion.
-- Tables Used: facility, lab_order
-- Complexity Features: INNER JOINs, GROUP BY, aggregates, conditional counting, handling division by zero

SELECT
    f.facility_id,
    f.facility_name,

    COUNT(lo.order_id) AS total_lab_orders,

    SUM(CASE WHEN lo.lab_priority = 'routine' THEN 1 ELSE 0 END) AS routine_count,
    SUM(CASE WHEN lo.lab_priority = 'urgent' THEN 1 ELSE 0 END) AS urgent_count,
    SUM(CASE WHEN lo.lab_priority = 'stat' THEN 1 ELSE 0 END) AS stat_count,

    ROUND(
        100.0 * SUM(CASE WHEN lo.lab_priority = 'routine' AND lo.is_completed = TRUE THEN 1 ELSE 0 END)
        / NULLIF(COUNT(CASE WHEN lo.lab_priority = 'routine' THEN 1 ELSE 0 END), 0),
        2
    ) AS routine_percent_completed, 
    ROUND(
        100.0 * SUM(CASE WHEN lo.lab_priority = 'urgent' AND lo.is_completed = TRUE THEN 1 ELSE 0 END)
        / NULLIF(COUNT(CASE WHEN lo.lab_priority = 'urgent' THEN 1 ELSE 0 END), 0),
        2
    ) AS urgent_percent_completed,
    ROUND(
        100.0 * SUM(CASE WHEN lo.lab_priority = 'stat' AND lo.is_completed = TRUE THEN 1 ELSE 0 END)
        / NULLIF(COUNT(CASE WHEN lo.lab_priority = 'stat' THEN 1 ELSE 0 END), 0),
        2
    ) AS stat_percent_completed

FROM lab_order lo
JOIN facility f
    ON lo.facility_id = f.facility_id

GROUP BY f.facility_id, f.facility_name
ORDER BY f.facility_id, f.facility_name DESC;

-- Expected Output: table of facilities with lab order counts by priority, ordered by total lab orders.
-- Columns: 

-- Sample Results:



-- Query #15: Prescription Refills
-- Operational Context: Shows all prescriptions that have been refilled in the past week.
-- Tables Used: prescription, patient, provider, medication
-- Complexity Features: INNER JOINs, GROUP BY, aggregates, conditional counting, handling division by zero

SELECT
    pat.MRN,
    pat.first_name AS patient_first_name,
    pat.last_name AS patient_last_name, 
    
    pr.prescription_id,
    pr.max_num_refills,
    pr.date_prescribed,
    pr.expiration_date,

    m.medication_name,

    COUNT(ref.prescription_id) as num_refills
FROM prescription pr
JOIN patient pat
    ON pr.MRN = pat.MRN
JOIN medication m
    ON pr.medication_id = m.medication_id
LEFT JOIN refill_history ref
    ON pr.prescription_id = ref.prescription_id
WHERE pr.max_num_refills > 0
  AND pr.date_prescribed >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY pr.prescription_id, pr.date_prescribed, pat.MRN, pat.first_name, pat.last_name, m.medication_name
ORDER BY pr.date_prescribed DESC, pat.last_name, pat.first_name, m.medication_name;


-- Expected Output: table of facilities with lab order counts by priority, ordered by total lab orders.
-- Columns: 

-- Sample Results: