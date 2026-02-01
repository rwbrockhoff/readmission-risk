-- Synthea EHR Schema
-- 30-Day Readmission Analysis

DROP TABLE IF EXISTS conditions CASCADE;
DROP TABLE IF EXISTS encounters CASCADE;
DROP TABLE IF EXISTS patients CASCADE;

CREATE TABLE patients (
    id UUID PRIMARY KEY,
    birthdate DATE NOT NULL,
    deathdate DATE,
    ssn VARCHAR(11),
    drivers VARCHAR(20),
    passport VARCHAR(20),
    prefix VARCHAR(10),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    suffix VARCHAR(10),
    maiden VARCHAR(50),
    marital VARCHAR(5),
    race VARCHAR(20),
    ethnicity VARCHAR(20),
    gender VARCHAR(5),
    birthplace VARCHAR(100),
    address VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    county VARCHAR(50),
    zip VARCHAR(10),
    lat DECIMAL(15, 12),
    lon DECIMAL(15, 12),
    healthcare_expenses DECIMAL(15, 4),
    healthcare_coverage DECIMAL(15, 4)
);

CREATE TABLE encounters (
    id UUID PRIMARY KEY,
    start_time TIMESTAMP NOT NULL,
    stop_time TIMESTAMP,
    patient_id UUID NOT NULL REFERENCES patients(id),
    organization_id UUID,
    provider_id UUID,
    payer_id UUID,
    encounterclass VARCHAR(20) NOT NULL,
    code VARCHAR(20),
    description VARCHAR(255),
    base_encounter_cost DECIMAL(10, 2),
    total_claim_cost DECIMAL(10, 2),
    payer_coverage DECIMAL(10, 2),
    reasoncode VARCHAR(20),
    reasondescription VARCHAR(255)
);

CREATE TABLE conditions (
    start_date DATE NOT NULL,
    stop_date DATE,
    patient_id UUID NOT NULL REFERENCES patients(id),
    encounter_id UUID REFERENCES encounters(id),
    code VARCHAR(20) NOT NULL,
    description VARCHAR(255)
);

-- Indexes for date-based queries
CREATE INDEX idx_encounters_patient ON encounters(patient_id);
CREATE INDEX idx_encounters_class ON encounters(encounterclass);
CREATE INDEX idx_encounters_start ON encounters(start_time);
CREATE INDEX idx_encounters_patient_start ON encounters(patient_id, start_time);

CREATE INDEX idx_conditions_patient ON conditions(patient_id);
CREATE INDEX idx_conditions_encounter ON conditions(encounter_id);
CREATE INDEX idx_conditions_code ON conditions(code);
