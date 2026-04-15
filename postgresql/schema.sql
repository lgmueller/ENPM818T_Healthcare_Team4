CREATE DATABASE healthcare_db;

-- enums for types
CREATE TYPE country_enum AS ENUM (
    'USA', 'CANADA', 'OTHER'
);

CREATE TYPE privilege_status_enum AS ENUM (
    'active',
    'inactive',
    'suspended'
);

CREATE TYPE slot_status_enum AS ENUM (
    'available',
    'booked',
    'blocked'
);

CREATE TYPE appointment_type_enum AS ENUM (
    'new_patient',
    'follow_up',
    'consultation',
    'urgent_care',
    'telehealth', 
    'routine_checkup', 
    'procedure'
);

CREATE TYPE appointment_status_enum AS ENUM (
    'scheduled',
    'completed',
    'cancelled',
    'no_show', 
    'confirmed', 
    'under_review'
);



-- function to automatically update time whenever a certain row/patient info is updated
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;





-- creating table provider
CREATE TABLE provider (
    provider_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    provider_type VARCHAR(50) NOT NULL,
    npi CHAR(10) UNIQUE,
    can_prescribe BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_npi_format
        CHECK (npi IS NULL OR npi ~ '^\d{10}$')
);


-- calling the function update to automatically update the timings
CREATE TRIGGER trg_provider_updated_at
BEFORE UPDATE ON provider
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();





-- Patient table
-- NOTE: SSN is stored as a 9-digit numeric string to satisfy schema-level validation (CHECK constraint). While real-world SSNs are formatted as XXX-XX-XXXX, hyphens are excluded to enforce consistent storage and validation.

CREATE TABLE patient (
    MRN CHAR(10) PRIMARY KEY,

    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,

    dob DATE NOT NULL,
    gender CHAR(1),
    blood_type VARCHAR(3),

    street VARCHAR(100),
    city VARCHAR(50),
    state CHAR(2),
    zipcode CHAR(5),
    country country_enum,

    organ_donor_status BOOLEAN DEFAULT FALSE,

    height_in INTEGER,
    weight_lbs INTEGER,

    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,

    ssn CHAR(9),
    has_insurance BOOLEAN DEFAULT FALSE,
    insurance VARCHAR(100),

    primary_provider_id INTEGER,
    communication_pref VARCHAR(50),
    pharmacy_pref VARCHAR(100),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,


    CONSTRAINT fk_patient_primary_provider
        FOREIGN KEY (primary_provider_id)
        REFERENCES provider(provider_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT chk_mrn_format
        CHECK (MRN ~ '^\d{10}$'),

    CONSTRAINT chk_dob_past
        CHECK (dob < CURRENT_DATE),

    CONSTRAINT chk_gender
        CHECK (gender IS NULL OR gender IN ('M', 'F', 'O')),

    CONSTRAINT chk_blood_type
        CHECK (
            blood_type IS NULL OR blood_type IN
            ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')
        ),

    CONSTRAINT chk_zipcode_format
        CHECK (zipcode IS NULL OR zipcode ~ '^\d{5}$'),

    CONSTRAINT chk_ssn_format
        CHECK (ssn IS NULL OR ssn ~ '^\d{9}$'),

    CONSTRAINT chk_height_positive
        CHECK (height_in IS NULL OR height_in > 0),

    CONSTRAINT chk_weight_positive
        CHECK (weight_lbs IS NULL OR weight_lbs > 0)
);



--calling the function to update automatically
CREATE TRIGGER trg_patient_updated_at
BEFORE UPDATE ON patient
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


-- creating index to for search to be easier
CREATE INDEX idx_patient_primary_provider
ON patient(primary_provider_id);










-- table facility
CREATE TABLE facility (
    facility_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    facility_name VARCHAR(100) NOT NULL,
    facility_type VARCHAR(50) NOT NULL,
    phone CHAR(10),

    address_street VARCHAR(100),
    address_city VARCHAR(50),
    address_state CHAR(2),
    address_zipcode CHAR(5),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_facility_phone
        CHECK (phone IS NULL OR phone ~ '^\d{10}$'),

    CONSTRAINT chk_facility_zipcode
        CHECK (address_zipcode IS NULL OR address_zipcode ~ '^\d{5}$')
);

-- auto update
CREATE TRIGGER trg_facility_updated_at
BEFORE UPDATE ON facility
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();









-- creating table provider_facility_privilege
CREATE TABLE provider_facility_privilege (
    privilege_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    provider_id INTEGER NOT NULL,
    facility_id INTEGER NOT NULL,

    privilege_type VARCHAR(50) NOT NULL,
    privilege_status privilege_status_enum NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_privilege_provider
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_privilege_facility
        FOREIGN KEY (facility_id)
        REFERENCES facility(facility_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT uq_provider_facility_privilege
        UNIQUE (provider_id, facility_id, privilege_type)
);


-- auto update and indexing
CREATE TRIGGER trg_provider_facility_privilege_updated_at
BEFORE UPDATE ON provider_facility_privilege
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_privilege_provider
ON provider_facility_privilege(provider_id);

CREATE INDEX idx_privilege_facility
ON provider_facility_privilege(facility_id);








-- table provider_availability
CREATE TABLE provider_availability (
    slot_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    provider_id INTEGER NOT NULL,
    facility_id INTEGER NOT NULL,

    slot_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_status slot_status_enum NOT NULL DEFAULT 'available',

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_availability_provider
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_availability_facility
        FOREIGN KEY (facility_id)
        REFERENCES facility(facility_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_slot_time_order
        CHECK (start_time < end_time),

    CONSTRAINT uq_provider_slot
        UNIQUE (provider_id, facility_id, slot_date, start_time, end_time)
);


--auto update and indexing
CREATE TRIGGER trg_provider_availability_updated_at
BEFORE UPDATE ON provider_availability
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_availability_provider_date
ON provider_availability(provider_id, slot_date);

CREATE INDEX idx_availability_facility_date
ON provider_availability(facility_id, slot_date);






-- table appointment
CREATE TABLE appointment (
    appointment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    MRN CHAR(10) NOT NULL,
    slot_id INTEGER NOT NULL UNIQUE,
    appt_type appointment_type_enum NOT NULL,
    appt_status appointment_status_enum NOT NULL DEFAULT 'scheduled',
    visit_reason VARCHAR(255),
    previous_admission_id INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_appointment_patient
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_appointment_slot
        FOREIGN KEY (slot_id)
        REFERENCES provider_availability(slot_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- auto-update and indexing
CREATE TRIGGER trg_appointment_updated_at
BEFORE UPDATE ON appointment
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_appointment_patient
ON appointment(MRN);

CREATE INDEX idx_appointment_status
ON appointment(appt_status);






-- table phone_numbers
CREATE TABLE phone_numbers (
    MRN CHAR(10) NOT NULL,
    number CHAR(10) NOT NULL,

    CONSTRAINT pk_phone_numbers
        PRIMARY KEY (MRN, number),

    CONSTRAINT fk_phone_patient
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_phone_number
        CHECK (number ~ '^\d{10}$')
);


-- table emails
CREATE TABLE emails (
    MRN CHAR(10) NOT NULL,
    email VARCHAR(100) NOT NULL,

    CONSTRAINT pk_emails
        PRIMARY KEY (MRN, email),

    CONSTRAINT fk_email_patient
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- emergency_contacts
CREATE TABLE emergency_contacts (
    MRN CHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50),
    phone CHAR(10) NOT NULL,

    CONSTRAINT pk_emergency_contacts
        PRIMARY KEY (MRN, phone),

    CONSTRAINT fk_emergency_patient
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_emergency_phone
        CHECK (phone ~ '^\d{10}$')
);


-- condition
CREATE TABLE condition (
    condition_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    condition_name VARCHAR(100) NOT NULL UNIQUE
);

-- table patient_condition
CREATE TABLE patient_condition (
    MRN CHAR(10) NOT NULL,
    condition_id INTEGER NOT NULL,
    diagnosis_date DATE,
    status VARCHAR(50),
    notes TEXT,

    CONSTRAINT pk_patient_condition
        PRIMARY KEY (MRN, condition_id),

    CONSTRAINT fk_patient_condition_patient
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_patient_condition_condition
        FOREIGN KEY (condition_id)
        REFERENCES condition(condition_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- allergy
CREATE TABLE allergy (
    allergy_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    allergen_name VARCHAR(100) NOT NULL UNIQUE
);



-- table patient_allergy
CREATE TABLE patient_allergy (
    MRN CHAR(10) NOT NULL,
    allergy_id INTEGER NOT NULL,
    reaction VARCHAR(100),
    severity VARCHAR(50),
    date_recorded DATE,

    CONSTRAINT pk_patient_allergy
        PRIMARY KEY (MRN, allergy_id),

    CONSTRAINT fk_patient_allergy_patient
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_patient_allergy_allergy
        FOREIGN KEY (allergy_id)
        REFERENCES allergy(allergy_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- med_license
CREATE TABLE med_license (
    license_no VARCHAR(30) PRIMARY KEY,
    provider_id INTEGER NOT NULL,
    state CHAR(2) NOT NULL,
    expiration_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_med_license_provider
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_med_license_state
        CHECK (state ~ '^[A-Z]{2}$')
);


-- auto update
CREATE TRIGGER trg_med_license_updated_at
BEFORE UPDATE ON med_license
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();




-- tab;e board_certs
CREATE TABLE board_certs (
    provider_id INTEGER NOT NULL,
    certification VARCHAR(100) NOT NULL,

    CONSTRAINT pk_board_certs
        PRIMARY KEY (provider_id, certification),

    CONSTRAINT fk_board_certs_provider
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- table speacialty
CREATE TABLE speciality (
    provider_id INTEGER NOT NULL,
    specialty VARCHAR(100) NOT NULL,

    CONSTRAINT pk_specialty
        PRIMARY KEY (provider_id, specialty),

    CONSTRAINT fk_specialty_provider
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- med_degrees
CREATE TABLE med_degrees (
    provider_id INTEGER NOT NULL,
    degree VARCHAR(50) NOT NULL,
    school VARCHAR(150) NOT NULL,

    CONSTRAINT pk_med_degrees
        PRIMARY KEY (provider_id, degree, school),

    CONSTRAINT fk_med_degrees_provider
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);




-- dea_no
CREATE TABLE dea_no (
    dea_no CHAR(9) PRIMARY KEY,
    provider_id INTEGER NOT NULL,
    state CHAR(2) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dea_provider
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_dea_format
        CHECK (dea_no ~ '^[A-Z]{2}[0-9]{7}$'),

    CONSTRAINT chk_dea_state
        CHECK (state ~ '^[A-Z]{2}$')
);

-- autoupdate
CREATE TRIGGER trg_dea_no_updated_at
BEFORE UPDATE ON dea_no
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();





CREATE TABLE hospital_room (
    room_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    facility_id INTEGER NOT NULL,
    room_number VARCHAR(10) NOT NULL,
    building VARCHAR(50),
    floor INTEGER,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    room_type VARCHAR(50) NOT NULL,
    capacity INTEGER NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_room_facility
        FOREIGN KEY (facility_id)
        REFERENCES facility(facility_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT uq_room_per_facility
        UNIQUE (facility_id, room_number),

    CONSTRAINT chk_room_capacity
        CHECK (capacity > 0)
);


CREATE TRIGGER trg_hospital_room_updated_at
BEFORE UPDATE ON hospital_room
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();




CREATE TYPE hospital_admission_type AS ENUM (
    'emergency', 'urgent', 'elective', 'observation'
);

CREATE TABLE admission (
    admission_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    MRN CHAR(10) NOT NULL, 
    provider_id INTEGER, 
    room_id INTEGER, 
    admission_datetime TIMESTAMPTZ NOT NULL, 
    admission_diagnosis TEXT, 
    admission_type hospital_admission_type NOT NULL, 
    expected_length_of_stay VARCHAR(50),
    discharge_datetime TIMESTAMPTZ, 
    discharge_disposition TEXT, 
    discharge_diagnosis TEXT, 
    discharge_instructions TEXT, 

    CONSTRAINT fk_admission_MRN
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE,
    CONSTRAINT fk_admission_provider_id
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_admission_room_id 
        FOREIGN KEY (room_id)
        REFERENCES hospital_room(room_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_time_admitted 
        CHECK (discharge_datetime IS NULL OR admission_datetime < discharge_datetime)
);

CREATE TABLE medication (
    medication_id INTEGER GENERATED ALWAYS AS IDENTITY  
        (START WITH 10 INCREMENT BY 1)
        PRIMARY KEY, 
    medication_name VARCHAR(30) NOT NULL, 
    schedule VARCHAR(2),

    CONSTRAINT chk_med_schedule
        CHECK (schedule is NULL OR schedule IN ('I', 'II', 'III', 'IV', 'V'))
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
    MRN CHAR(10) NOT NULL, 
    provider_id INTEGER, 
    medication_id INTEGER NOT NULL, 
    date_prescribed TIMESTAMPTZ NOT NULL, 
    expiration_date TIMESTAMPTZ, 
    dosage TEXT, 
    frequency TEXT, 
    duration TEXT, 
    prescription_status prescription_status NOT NULL, 
    max_num_refills INTEGER NOT NULL, 
    special_instructions TEXT,
    
    CONSTRAINT fk_prescription_MRN
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE,
    CONSTRAINT fk_prescription_provider_id
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_prescription_medication_id 
        FOREIGN KEY (medication_id)
        REFERENCES medication(medication_id)
        ON DELETE CASCADE
);

CREATE TABLE refill_history (
    prescription_id INTEGER NOT NULL, 
    date_refilled TIMESTAMPTZ NOT NULL, 
    pharmacy VARCHAR(30),

    CONSTRAINT pk_refill_history
        PRIMARY KEY (prescription_id, date_refilled),
    CONSTRAINT fk_refill_history_prescription_id 
        FOREIGN KEY (prescription_id)
        REFERENCES prescription(prescription_id)
        ON DELETE CASCADE
);

CREATE TYPE lab_priority as ENUM (
    'routine', 'urgent', 'stat'
);

CREATE TABLE lab_order (
    order_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    MRN CHAR(10) NOT NULL,
    provider_id INTEGER, 
    facility_id INTEGER,
    date_ordered TIMESTAMPTZ NOT NULL, 
    lab_priority lab_priority NOT NULL, 
    is_completed BOOLEAN NOT NULL,

    CONSTRAINT fk_lab_order_MRN
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE,
    CONSTRAINT fk_lab_order_provider_id
        FOREIGN KEY (provider_id)
        REFERENCES provider(provider_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_lab_order_facility_id 
        FOREIGN KEY (facility_id)
        REFERENCES facility(facility_id)
        ON DELETE SET NULL
    
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

    CONSTRAINT fk_lab_test_order_id
        FOREIGN KEY (order_id)
        REFERENCES lab_order(order_id)
        ON DELETE CASCADE
);

CREATE TABLE insurance (
    insurance_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    MRN CHAR(10) NOT NULL,
    policy_no VARCHAR(20) NOT NULL, 
    group_no VARCHAR(10) NOT NULL, 
    copay_amount NUMERIC(10,2) NOT NULL, 
    coverage VARCHAR(100) NOT NULL, 
    insurance_company VARCHAR(100) NOT NULL,
    effective_date TIMESTAMPTZ NOT NULL, 
    termination_date TIMESTAMPTZ NOT NULL, 

    CONSTRAINT fk_lab_test_MRN
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE,
    CONSTRAINT chk_insurance_dates 
        CHECK (effective_date < termination_date),
    CONSTRAINT chk_insurance_copay 
        CHECK (copay_amount >= 0.0)
);

CREATE TYPE insurance_claim_status AS ENUM (
    'draft', 'submitted', 'pending', 'approved', 'denied', 'appealed', 'partially_approved', 'under_review'
);

CREATE TABLE insurance_claim (
    claim_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    MRN CHAR(10) NOT NULL,
    service_date TIMESTAMPTZ NOT NULL, 
    charge_amount NUMERIC(10,2) NOT NULL, 
    insurance_claim_status insurance_claim_status NOT NULL, 
    patient_responsibility NUMERIC(10,2) NOT NULL, 
    denial_reason TEXT,

    CONSTRAINT fk_insurance_claim_MRN
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE,
    CONSTRAINT chk_claim_amounts 
        CHECK (charge_amount >= 0.0 AND patient_responsibility >= 0.0)
);

CREATE TABLE payment (
    payment_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY, 
    claim_id INTEGER NOT NULL, 
    MRN CHAR(10) NOT NULL, 
    amount NUMERIC(10,2) NOT NULL, 
    payment_date TIMESTAMPTZ NOT NULL, 
    payment_source VARCHAR(100),

    CONSTRAINT fk_payment_MRN
        FOREIGN KEY (MRN)
        REFERENCES patient(MRN)
        ON DELETE CASCADE,
    CONSTRAINT fk_payment_insurance_claim_id
        FOREIGN KEY (claim_id)
        REFERENCES insurance_claim(claim_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_payment_amount
        CHECK (amount >= 0.0)
);

CREATE TABLE insurance_diagnosis_codes (
    insurance_claim INTEGER NOT NULL, 
    diagnosis VARCHAR(100), 
    notes TEXT,

    CONSTRAINT fk_insurance_diagnosis_code_insurance_claim
        FOREIGN KEY (insurance_claim)
        REFERENCES insurance_claim(claim_id)
        ON DELETE CASCADE,
    CONSTRAINT pk_insurance_diagnosis 
        PRIMARY KEY (insurance_claim, diagnosis)
);

CREATE TABLE insurance_procedures_codes (
    insurance_claim INTEGER NOT NULL, 
    procedure_code VARCHAR(100), 
    notes TEXT,

    CONSTRAINT fk_insurance_procedure_code_insurance_claim
        FOREIGN KEY (insurance_claim)
        REFERENCES insurance_claim(claim_id)
        ON DELETE CASCADE,
    CONSTRAINT pk_insurance_procedure_code 
        PRIMARY KEY (insurance_claim, procedure_code)
);