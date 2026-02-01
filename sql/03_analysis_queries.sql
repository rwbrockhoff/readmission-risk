-- 30-Day Readmission Analysis
-- Heart failure cohort from Synthea synthetic EHR data

-- Population overview
SELECT
    COUNT(DISTINCT p.id) as total_patients,
    COUNT(DISTINCT CASE WHEN e.encounterclass = 'inpatient' THEN p.id END) as patients_with_inpatient,
    COUNT(CASE WHEN e.encounterclass = 'inpatient' THEN 1 END) as total_inpatient_encounters
FROM patients p
LEFT JOIN encounters e ON p.id = e.patient_id;

-- Heart failure cohort (SNOMED 88805009 = Chronic congestive heart failure)
SELECT
    COUNT(DISTINCT patient_id) as hf_patients,
    COUNT(*) as hf_condition_records
FROM conditions
WHERE code = '88805009';


-- Index admissions for HF patients
WITH hf_patients AS (
    SELECT DISTINCT patient_id
    FROM conditions
    WHERE code = '88805009'
),
hf_inpatient_encounters AS (
    SELECT
        e.id as encounter_id,
        e.patient_id,
        e.start_time as admission_date,
        e.stop_time as discharge_date,
        e.description as encounter_type,
        e.reasondescription as admission_reason
    FROM encounters e
    INNER JOIN hf_patients hf ON e.patient_id = hf.patient_id
    WHERE e.encounterclass = 'inpatient'
      AND e.stop_time IS NOT NULL
)
SELECT
    COUNT(*) as hf_inpatient_count,
    COUNT(DISTINCT patient_id) as unique_hf_patients_with_inpatient
FROM hf_inpatient_encounters;


-- 30-day readmission rate
WITH hf_patients AS (
    SELECT DISTINCT patient_id
    FROM conditions
    WHERE code = '88805009'
),
hf_admissions AS (
    SELECT
        e.id as encounter_id,
        e.patient_id,
        e.start_time as admission_date,
        e.stop_time as discharge_date,
        LEAD(e.start_time) OVER (
            PARTITION BY e.patient_id
            ORDER BY e.start_time
        ) as next_admission_date
    FROM encounters e
    INNER JOIN hf_patients hf ON e.patient_id = hf.patient_id
    WHERE e.encounterclass = 'inpatient'
      AND e.stop_time IS NOT NULL
),
readmission_flags AS (
    SELECT
        encounter_id,
        patient_id,
        admission_date,
        discharge_date,
        next_admission_date,
        EXTRACT(DAY FROM (next_admission_date - discharge_date)) as days_to_readmission,
        CASE
            WHEN next_admission_date IS NOT NULL
             AND EXTRACT(DAY FROM (next_admission_date - discharge_date)) <= 30
            THEN 1
            ELSE 0
        END as readmit_30_day_flag
    FROM hf_admissions
)
SELECT
    COUNT(*) as total_index_admissions,
    SUM(readmit_30_day_flag) as readmissions_30_day,
    ROUND(100.0 * SUM(readmit_30_day_flag) / COUNT(*), 2) as readmission_rate_pct
FROM readmission_flags;


-- Full cohort with demographics
WITH hf_patients AS (
    SELECT DISTINCT patient_id
    FROM conditions
    WHERE code = '88805009'
),
hf_admissions AS (
    SELECT
        e.id as encounter_id,
        e.patient_id,
        e.start_time as admission_date,
        e.stop_time as discharge_date,
        LEAD(e.start_time) OVER (
            PARTITION BY e.patient_id
            ORDER BY e.start_time
        ) as next_admission_date,
        ROW_NUMBER() OVER (
            PARTITION BY e.patient_id
            ORDER BY e.start_time
        ) as admission_sequence
    FROM encounters e
    INNER JOIN hf_patients hf ON e.patient_id = hf.patient_id
    WHERE e.encounterclass = 'inpatient'
      AND e.stop_time IS NOT NULL
),
readmission_cohort AS (
    SELECT
        ha.encounter_id,
        ha.patient_id,
        ha.admission_date,
        ha.discharge_date,
        ha.next_admission_date,
        ha.admission_sequence,
        EXTRACT(DAY FROM (ha.next_admission_date - ha.discharge_date)) as days_to_readmission,
        CASE
            WHEN ha.next_admission_date IS NOT NULL
             AND EXTRACT(DAY FROM (ha.next_admission_date - ha.discharge_date)) <= 30
            THEN 1
            ELSE 0
        END as readmit_30_day_flag,
        p.birthdate,
        EXTRACT(YEAR FROM AGE(ha.admission_date, p.birthdate)) as age_at_admission,
        p.gender,
        p.race,
        p.ethnicity
    FROM hf_admissions ha
    INNER JOIN patients p ON ha.patient_id = p.id
)
SELECT * FROM readmission_cohort
LIMIT 20;


-- Readmission rate by age group
WITH hf_patients AS (
    SELECT DISTINCT patient_id
    FROM conditions
    WHERE code = '88805009'
),
hf_admissions AS (
    SELECT
        e.id as encounter_id,
        e.patient_id,
        e.start_time as admission_date,
        e.stop_time as discharge_date,
        LEAD(e.start_time) OVER (
            PARTITION BY e.patient_id
            ORDER BY e.start_time
        ) as next_admission_date
    FROM encounters e
    INNER JOIN hf_patients hf ON e.patient_id = hf.patient_id
    WHERE e.encounterclass = 'inpatient'
      AND e.stop_time IS NOT NULL
),
readmission_cohort AS (
    SELECT
        ha.*,
        CASE
            WHEN ha.next_admission_date IS NOT NULL
             AND EXTRACT(DAY FROM (ha.next_admission_date - ha.discharge_date)) <= 30
            THEN 1
            ELSE 0
        END as readmit_30_day_flag,
        EXTRACT(YEAR FROM AGE(ha.admission_date, p.birthdate)) as age_at_admission
    FROM hf_admissions ha
    INNER JOIN patients p ON ha.patient_id = p.id
)
SELECT
    CASE
        WHEN age_at_admission < 50 THEN '18-49'
        WHEN age_at_admission < 65 THEN '50-64'
        WHEN age_at_admission < 75 THEN '65-74'
        WHEN age_at_admission < 85 THEN '75-84'
        ELSE '85+'
    END as age_group,
    COUNT(*) as admissions,
    SUM(readmit_30_day_flag) as readmissions,
    ROUND(100.0 * SUM(readmit_30_day_flag) / COUNT(*), 2) as readmission_rate_pct
FROM readmission_cohort
GROUP BY 1
ORDER BY 1;


-- Readmission rate by gender
WITH hf_patients AS (
    SELECT DISTINCT patient_id
    FROM conditions
    WHERE code = '88805009'
),
hf_admissions AS (
    SELECT
        e.id as encounter_id,
        e.patient_id,
        e.start_time as admission_date,
        e.stop_time as discharge_date,
        LEAD(e.start_time) OVER (
            PARTITION BY e.patient_id
            ORDER BY e.start_time
        ) as next_admission_date
    FROM encounters e
    INNER JOIN hf_patients hf ON e.patient_id = hf.patient_id
    WHERE e.encounterclass = 'inpatient'
      AND e.stop_time IS NOT NULL
),
readmission_cohort AS (
    SELECT
        ha.*,
        CASE
            WHEN ha.next_admission_date IS NOT NULL
             AND EXTRACT(DAY FROM (ha.next_admission_date - ha.discharge_date)) <= 30
            THEN 1
            ELSE 0
        END as readmit_30_day_flag,
        p.gender
    FROM hf_admissions ha
    INNER JOIN patients p ON ha.patient_id = p.id
)
SELECT
    gender,
    COUNT(*) as admissions,
    SUM(readmit_30_day_flag) as readmissions,
    ROUND(100.0 * SUM(readmit_30_day_flag) / COUNT(*), 2) as readmission_rate_pct
FROM readmission_cohort
GROUP BY gender
ORDER BY gender;


-- Readmission rate by race
WITH hf_patients AS (
    SELECT DISTINCT patient_id
    FROM conditions
    WHERE code = '88805009'
),
hf_admissions AS (
    SELECT
        e.id as encounter_id,
        e.patient_id,
        e.start_time as admission_date,
        e.stop_time as discharge_date,
        LEAD(e.start_time) OVER (
            PARTITION BY e.patient_id
            ORDER BY e.start_time
        ) as next_admission_date
    FROM encounters e
    INNER JOIN hf_patients hf ON e.patient_id = hf.patient_id
    WHERE e.encounterclass = 'inpatient'
      AND e.stop_time IS NOT NULL
),
readmission_cohort AS (
    SELECT
        ha.*,
        CASE
            WHEN ha.next_admission_date IS NOT NULL
             AND EXTRACT(DAY FROM (ha.next_admission_date - ha.discharge_date)) <= 30
            THEN 1
            ELSE 0
        END as readmit_30_day_flag,
        p.race
    FROM hf_admissions ha
    INNER JOIN patients p ON ha.patient_id = p.id
)
SELECT
    race,
    COUNT(*) as admissions,
    SUM(readmit_30_day_flag) as readmissions,
    ROUND(100.0 * SUM(readmit_30_day_flag) / COUNT(*), 2) as readmission_rate_pct
FROM readmission_cohort
GROUP BY race
ORDER BY admissions DESC;


-- Days to readmission distribution
WITH hf_patients AS (
    SELECT DISTINCT patient_id
    FROM conditions
    WHERE code = '88805009'
),
hf_admissions AS (
    SELECT
        e.patient_id,
        e.stop_time as discharge_date,
        LEAD(e.start_time) OVER (
            PARTITION BY e.patient_id
            ORDER BY e.start_time
        ) as next_admission_date
    FROM encounters e
    INNER JOIN hf_patients hf ON e.patient_id = hf.patient_id
    WHERE e.encounterclass = 'inpatient'
      AND e.stop_time IS NOT NULL
),
days_to_readmit AS (
    SELECT
        EXTRACT(DAY FROM (next_admission_date - discharge_date))::INT as days_to_readmission
    FROM hf_admissions
    WHERE next_admission_date IS NOT NULL
      AND EXTRACT(DAY FROM (next_admission_date - discharge_date)) <= 30
      AND EXTRACT(DAY FROM (next_admission_date - discharge_date)) >= 0
)
SELECT
    CASE
        WHEN days_to_readmission BETWEEN 0 AND 7 THEN '0-7 days'
        WHEN days_to_readmission BETWEEN 8 AND 14 THEN '8-14 days'
        WHEN days_to_readmission BETWEEN 15 AND 21 THEN '15-21 days'
        WHEN days_to_readmission BETWEEN 22 AND 30 THEN '22-30 days'
    END as readmission_window,
    COUNT(*) as readmissions,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_of_readmissions
FROM days_to_readmit
GROUP BY 1
ORDER BY 1;


-- Admission frequency per patient
WITH hf_patients AS (
    SELECT DISTINCT patient_id
    FROM conditions
    WHERE code = '88805009'
),
admission_counts AS (
    SELECT
        e.patient_id,
        COUNT(*) as admission_count
    FROM encounters e
    INNER JOIN hf_patients hf ON e.patient_id = hf.patient_id
    WHERE e.encounterclass = 'inpatient'
    GROUP BY e.patient_id
)
SELECT
    CASE
        WHEN admission_count = 1 THEN '1 admission'
        WHEN admission_count = 2 THEN '2 admissions'
        WHEN admission_count = 3 THEN '3 admissions'
        WHEN admission_count BETWEEN 4 AND 5 THEN '4-5 admissions'
        ELSE '6+ admissions'
    END as admission_frequency,
    COUNT(*) as patients,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_of_patients
FROM admission_counts
GROUP BY 1
ORDER BY MIN(admission_count);


-- Readmission by number of conditions
WITH hf_patients AS (
    SELECT DISTINCT patient_id
    FROM conditions
    WHERE code = '88805009'
),
hf_admissions AS (
    SELECT
        e.id as encounter_id,
        e.patient_id,
        e.start_time as admission_date,
        e.stop_time as discharge_date,
        LEAD(e.start_time) OVER (
            PARTITION BY e.patient_id
            ORDER BY e.start_time
        ) as next_admission_date
    FROM encounters e
    INNER JOIN hf_patients hf ON e.patient_id = hf.patient_id
    WHERE e.encounterclass = 'inpatient'
      AND e.stop_time IS NOT NULL
),
patient_conditions AS (
    SELECT
        patient_id,
        COUNT(DISTINCT code) as condition_count
    FROM conditions
    GROUP BY patient_id
),
readmission_with_conditions AS (
    SELECT
        ha.patient_id,
        CASE
            WHEN ha.next_admission_date IS NOT NULL
             AND EXTRACT(DAY FROM (ha.next_admission_date - ha.discharge_date)) <= 30
            THEN 1
            ELSE 0
        END as readmit_30_day_flag,
        COALESCE(pc.condition_count, 0) as condition_count
    FROM hf_admissions ha
    LEFT JOIN patient_conditions pc ON ha.patient_id = pc.patient_id
)
SELECT
    CASE
        WHEN condition_count <= 5 THEN '1-5 conditions'
        WHEN condition_count <= 10 THEN '6-10 conditions'
        WHEN condition_count <= 15 THEN '11-15 conditions'
        ELSE '16+ conditions'
    END as condition_group,
    COUNT(*) as admissions,
    SUM(readmit_30_day_flag) as readmissions,
    ROUND(100.0 * SUM(readmit_30_day_flag) / COUNT(*), 2) as readmission_rate_pct
FROM readmission_with_conditions
GROUP BY 1
ORDER BY MIN(condition_count);
