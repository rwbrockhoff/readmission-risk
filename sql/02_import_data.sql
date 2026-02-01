-- Data Import
-- Update file paths if needed

\copy patients(id, birthdate, deathdate, ssn, drivers, passport, prefix, first_name, last_name, suffix, maiden, marital, race, ethnicity, gender, birthplace, address, city, state, county, zip, lat, lon, healthcare_expenses, healthcare_coverage) FROM 'data/raw/patients.csv' WITH (FORMAT csv, HEADER true);

\copy encounters(id, start_time, stop_time, patient_id, organization_id, provider_id, payer_id, encounterclass, code, description, base_encounter_cost, total_claim_cost, payer_coverage, reasoncode, reasondescription) FROM 'data/raw/encounters.csv' WITH (FORMAT csv, HEADER true);

\copy conditions(start_date, stop_date, patient_id, encounter_id, code, description) FROM 'data/raw/conditions.csv' WITH (FORMAT csv, HEADER true);

-- Verify counts
SELECT 'patients' as table_name, COUNT(*) as rows FROM patients
UNION ALL
SELECT 'encounters', COUNT(*) FROM encounters
UNION ALL
SELECT 'conditions', COUNT(*) FROM conditions;

-- Heart failure cohort size (SNOMED 88805009)
SELECT COUNT(DISTINCT patient_id) as hf_patients FROM conditions WHERE code = '88805009';

-- Inpatient encounters
SELECT COUNT(*) as inpatient_encounters FROM encounters WHERE encounterclass = 'inpatient';
