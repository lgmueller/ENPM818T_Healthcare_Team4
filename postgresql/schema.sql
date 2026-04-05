CREATE DATABASE healthcare_db;

CREATE TABLE patient ();

CREATE TABLE phone_numbers ();

CREATE TABLE emails ();

CREATE TABLE emergency_contacts ();

CREATE TABLE patient_condition ();

CREATE TABLE condition ();

CREATE TABLE patient_allergy ();

CREATE TABLE provider ();

CREATE TABLE medical_license ();

CREATE TABLE board_certs ();

CREATE TABLE specialty ();

CREATE TABLE medical_degrees ();

CREATE TABLE DEA_no ();

CREATE TABLE physician_availability ();

CREATE TABLE appointment ();

CREATE TABLE facility ();

CREATE TABLE hospital_room ();

CREATE TYPE hospital_admission_type AS ENUM (
    'emergency', 'urgent', 'elective', 'observation'
);

CREATE TABLE admission (
    admission_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    patient_id INTEGER NOT NULL, 
    provider_id INTEGER NOT NULL, 
    room_id INTEGER NOT NULL, 
    admission_datetime TIMESTAMPTZ NOT NULL, 
    admission_diagnosis TEXT, 
    admission_type hospital_admission_type NOT NULL, 
    expected_length_of_stay VARCHAR(50)
    discharge_datetime TIMESTAMPTZ, 
    discharge_disposition TEXT, 
    discharge_diagnosis TEXT, 
    discharage_instructions TEXT, 

    CONSTRAINT fk_patient_id
        FOREIGN KEY (patient_id)
        REFERENCES patient(patient_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_provider_id
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_room_id 
        FOREIGN KEY (room_id)
        REFERENCES room(room_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_time_admitted 
        CHECK (admission_datetime < discharge_datetime),
);

CREATE TABLE medication (
    medication_id INTEGER GENERATED ALWAYS AS IDENTITY  
        (START WITH 10 INCREMENT BY 1)
        PRIMARY KEY, 
    medication_name VARCHAR(30) NOT NULL, 
    schedule VARCHAR(2),

    CONSTRAINT chk_med_schedule
        CHECK (schedule IN ('I', 'II', 'III', 'IV', 'V'))
);

CREATE TYPE prescription_status as ENUM (
    'active', 
    'completed',
    'discontinued', 
    'cancelled'
);

CREATE TABLE prescription (
    prescription_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    patient_id INTEGER NOT NULL, 
    provider_id INTEGER NOT NULL, 
    medication_id INTEGER NOT NULL, 
    date_prescribed TIMESTAMPTZ NOT NULL, 
    expiration_date TIMESTAMPTZ, 
    dosage TEXT, 
    frequency TEXT, 
    duration TEXT, 
    prescription_status prescription_status NOT NULL, 
    max_num_refills INTEGER NOT NULL, 
    special_instructions TEXT,
    
    CONSTRAINT fk_patient_id
        FOREIGN KEY (patient_id)
        REFERENCES patient(patient_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_provider_id
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_medication_id 
        FOREIGN KEY (medication_id)
        REFERENCES medication(medication_id)
        ON DELETE CASCADE,
);

CREATE TABLE refill_history (
    prescription_id INTEGER NOT NULL, 
    date_refilled TIMESTAMPTZ NOT NULL, 
    pharmacy VARCHAR(30),

    CONSTRAINT pk_refill_history
        PRIMARY KEY (prescription_id, date_refilled)
    CONSTRAINT fk_prescription_id 
        FOREIGN KEY (prescription_id)
        REFERENCES prescription(prescription_id)
        ON DELETE CASCADE,
);

CREATE TYPE lab_priority as ENUM (
    'routine', 'urgent', 'stat'
);

CREATE TABLE lab_order (
    order_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    patient_id INTEGER NOT NULL,
    provider_id INTEGER NOT NULL, 
    facility_id INTEGER NOT NULL,
    date_ordered TIMESTAMPTZ NOT NULL, 
    lab_priority lab_priority NOT NULL, 
    is_completed BOOLEAN NOT NULL,

    CONSTRAINT fk_patient_id
        FOREIGN KEY (patient_id)
        REFERENCES patient(patient_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_provider_id
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE SET NULL,
    CONSTRAINT facility_id 
        FOREIGN KEY (facility_id)
        REFERENCES facility(facility_id)
        ON DELETE SET NULL,
    
);

CREATE TABLE lab_test (
    test_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    order_id INTEGER NOT NULL, 
    test_type VARCHAR(30) NOT NULL, 
    date_of_completion TIMESTAMPTZ NOT NULL, 
    pass_flag BOOLEAN NOT NULL, 
    test_value_result VARCHAR(50) NOT NULL, 
    ref_range_low VARCHAR(50) NOT NULL, 
    ref_range_high VARCHAR(50) NOT NULL, 
    abnormal_flag BOOLEAN NOT NULL, 
    interpretation_notes TEXT,  

    CONSTRAINT fk_order_id
        FOREIGN KEY (order_id)
        REFERENCES lab_order(order_id)
        ON DELETE CASCADE,
);

CREATE TABLE insurance (
    insurance_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    patient_id INTEGER NOT NULL,
    policy_no VARCHAR(20) NOT NULL, 
    group_no VARCHAR(10) NOT NULL, 
    copay_amount NUMERIC(10,2) NOT NULL, 
    coverage VARCHAR(100) NOT NULL, 
    insurance_company VARCHAR(100) NOT NULL,
    effective_date TIMESTAMPTZ NOT NULL, 
    termination_date TIMESTAMPTZ NOT NULL, 

    CONSTRAINT fk_patient_id
        FOREIGN KEY (patient_id)
        REFERENCES patient(patient_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_insurance_dates 
        CHECK (effective_date < termination_date),
    CONSTRAINT chk_insurance_copay 
        CHECK (copay_amount >= 0.0),
);

CREATE TYPE insurance_claim_status AS ENUM (
    'draft', 'submitted', 'pending', 'approved', 'denied', 'appealed'
);

CREATE TABLE insurance_claim (
    claim_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    patient_id INTEGER NOT NULL,
    service_date TIMESTAMPTZ NOT NULL, 
    charge_amount NUMERIC(10,2) NOT NULL, 
    insurance_claim_status insurance_claim_status NOT NULL, 
    patient_responsibility NUMERIC(10,2) NOT NULL, 
    denial_reason TEXT,

    CONSTRAINT fk_patient_id
        FOREIGN KEY (patient_id)
        REFERENCES patient(patient_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_claim_amounts 
        CHECK (charge_amount >= 0.0 AND patient_responsibility >= 0.0)
);

CREATE TABLE payment (
    payment_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    claim_id INTEGER NOT NULL, 
    patient_id INTEGER NOT NULL, 
    amount NUMERIC(10,2) NOT NULL, 
    payment_date TIMESTAMPTZ NOT NULL, 
    payment_source VARCHAR(100),

    CONSTRAINT fk_patient_id
        FOREIGN KEY (patient_id)
        REFERENCES patient(patient_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_insurance_claim_id
        FOREIGN KEY (claim_id)
        REFERENCES insurance_claim(claim_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_payment_amount
        CHECK (amount >= 0.0),
);

CREATE TABLE insurance_diagnosis_codes (
    insurance_claim INTEGER NOT NULL, 
    diagnosis VARCHAR(100), 
    notes TEXT,

    CONSTRAINT pk_insurance_diagnosis 
        PRIMARY KEY (insurance_claim, diagnosis),
);

CREATE TABLE insurance_procedures_codes (
    insurance_claim INTEGER NOT NULL, 
    procedure_code VARCHAR(100), 
    notes TEXT,

    CONSTRAINT pk_insurance_procedure_code 
        PRIMARY KEY (insurance_claim, procedure_code),
);