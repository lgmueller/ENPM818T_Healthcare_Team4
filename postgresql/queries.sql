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