-- Create schema (if not exists)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'pm') EXEC('CREATE SCHEMA pm');

------------------------------------------------------------
-- 1 Lookup tables (no FKs)
------------------------------------------------------------
CREATE TABLE pm.PROVINCE (
    province_id INT IDENTITY(1,1) PRIMARY KEY,
    province NVARCHAR(100)
);

CREATE TABLE pm.CITY (
    city_id INT IDENTITY(1,1) PRIMARY KEY,
    city NVARCHAR(100)
);

CREATE TABLE pm.PROPERTY_TYPE (
    unit_type_id INT IDENTITY(1,1) PRIMARY KEY,
    unit_type NVARCHAR(100)
);

CREATE TABLE pm.INSPECTIONS_TYPE (
    inspection_type_id INT IDENTITY(1,1) PRIMARY KEY,
    inspection_type NVARCHAR(100)
);

CREATE TABLE pm.UTILITY_PAYER (
    payer_id INT IDENTITY(1,1) PRIMARY KEY
    -- seed examples: UP, LOW, Owner
);

CREATE TABLE pm.UTILITY_TYPE (
    utype_id INT IDENTITY(1,1) PRIMARY KEY
    -- seed examples: BC_Hydro, FortisBC
);

CREATE TABLE pm.MOVE_TYPE (
    move_type_id INT IDENTITY(1,1) PRIMARY KEY
    -- seed examples: Move Out, Move In
);

CREATE TABLE pm.CARE_OF (
    care_of_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(100),
    last_name  NVARCHAR(100),
    phone_number NVARCHAR(50),
    email NVARCHAR(255)
);

------------------------------------------------------------
-- 2 Core entity
------------------------------------------------------------
CREATE TABLE pm.PROPERTIES (
    property_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    address NVARCHAR(255),
    postal_code NVARCHAR(20),
    management_start_date DATE,
    length_of_service NVARCHAR(50),
    status NVARCHAR(50),
    storage_locker NVARCHAR(50),
    parking_stall NVARCHAR(50),
    remarks NVARCHAR(500),
    unit_type_id INT NULL,
    city_id INT NULL,
    province_id INT NULL,
    CONSTRAINT UQ_PROPERTIES UNIQUE (building_no, unit_number),
    FOREIGN KEY (unit_type_id) REFERENCES pm.PROPERTY_TYPE(unit_type_id),
    FOREIGN KEY (city_id)      REFERENCES pm.CITY(city_id),
    FOREIGN KEY (province_id)  REFERENCES pm.PROVINCE(province_id)
);

------------------------------------------------------------
-- 3 Owners + ownership + insurances (owner & property)
------------------------------------------------------------
CREATE TABLE pm.OWNERS (
    owner_id INT IDENTITY(1,1) PRIMARY KEY,
    care_of_id INT NULL,
    first_name NVARCHAR(100),
    last_name  NVARCHAR(100),
    company_name NVARCHAR(100),
    type_of_owner NVARCHAR(50),
    phone_number NVARCHAR(50),
    email NVARCHAR(255),
    CONSTRAINT FK_Owners_CareOf
        FOREIGN KEY (care_of_id) REFERENCES pm.CARE_OF(care_of_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE pm.OWNERSHIP (
    ownership_id INT IDENTITY(1,1) PRIMARY KEY,
    fm_owner_id INT NOT NULL,
    fm_property_id INT NOT NULL,
    CONSTRAINT FK_Ownership_Owner
        FOREIGN KEY (fm_owner_id) REFERENCES pm.OWNERS(owner_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_Ownership_Property
        FOREIGN KEY (fm_property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE pm.OWNER_INSURANCE (
    insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    insurance_number NVARCHAR(100),
    start_date DATE,
    end_date DATE,
    remarks NVARCHAR(255),
    CONSTRAINT FK_OwnerIns_Property
        FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- 4 Tenancy, tenants, tenant insurance, moves
------------------------------------------------------------
CREATE TABLE pm.TENANT_INSURANCE (
    insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    policy_number NVARCHAR(100),
    start_date DATE,
    end_date   DATE,
    remarks NVARCHAR(255)
);

CREATE TABLE pm.TENANCY (
    tenancy_id INT IDENTITY(1,1) PRIMARY KEY,
    insurance_id INT NULL,
    property_id INT NOT NULL,
    lease_start_date DATE,
    lease_end_date   DATE,
    lease_status NVARCHAR(50),
    term NVARCHAR(50),
    security_deposit_date DATE,
    security_deposit DECIMAL(10,2),
    pet_deposit DECIMAL(10,2),
    pet_deposit_date DATE,
    last_rent_increase DATE,
    CONSTRAINT UQ_TENANCY UNIQUE (property_id, lease_start_date),
    CONSTRAINT FK_Tenancy_Insurance FOREIGN KEY (insurance_id)
        REFERENCES pm.TENANT_INSURANCE(insurance_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT FK_Tenancy_Property FOREIGN KEY (property_id)
        REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE pm.TENANTS (
    tenant_id INT IDENTITY(1,1) PRIMARY KEY,
    tenancy_id INT NOT NULL,
    first_name NVARCHAR(100),
    last_name  NVARCHAR(100),
    email NVARCHAR(255),
    mobile NVARCHAR(50),
    CONSTRAINT FK_Tenants_Tenancy FOREIGN KEY (tenancy_id)
        REFERENCES pm.TENANCY(tenancy_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE pm.MOVE (
    move_id INT IDENTITY(1,1) PRIMARY KEY,
    move_type_id INT NOT NULL,
    tenancy_id INT NOT NULL,
    move_date DATE,
    tenant_availability NVARCHAR(50),
    proposed_date_tbc BIT,
    confirmed_with_david BIT,
    status NVARCHAR(50),
    notify_back_office BIT,
    security_release BIT,
    move_out_letter BIT,
    move_in_orientation BIT,
    form_k BIT,
    zinspector NVARCHAR(100),
    FOREIGN KEY (move_type_id) REFERENCES pm.MOVE_TYPE(move_type_id),
    FOREIGN KEY (tenancy_id)   REFERENCES pm.TENANCY(tenancy_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- 5 Inspections (types, events, issues)
------------------------------------------------------------
CREATE TABLE pm.INSPECTIONS (
    inspection_id INT IDENTITY(1,1) PRIMARY KEY,
    inspection_type_id INT NOT NULL,
    property_id INT NOT NULL,
    last_inspection_date DATE,
    need_inspection NVARCHAR(50),
    inspection_notes NVARCHAR(500),
    repairs_maintenance NVARCHAR(255),
    follow_up_date DATE NULL,
    FOREIGN KEY (inspection_type_id) REFERENCES pm.INSPECTIONS_TYPE(inspection_type_id),
    FOREIGN KEY (property_id)        REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE pm.INSPECTION_ISSUES (
    issue_id INT IDENTITY(1,1) PRIMARY KEY,
    inspection_id INT NOT NULL,
    description_of_issue NVARCHAR(MAX),
    action_plan NVARCHAR(MAX),
    checked_off_by NVARCHAR(100),
    status NVARCHAR(100),
    date_logged DATETIME DEFAULT(GETDATE()),
    FOREIGN KEY (inspection_id) REFERENCES pm.INSPECTIONS(inspection_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- 6 Assessments, taxes, managers, keys/fobs/buzzer
------------------------------------------------------------
CREATE TABLE pm.BC_ASSESSMENTS (
    assessment_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    [year] INT NOT NULL,
    assessed_value DECIMAL(12,2),
    CONSTRAINT UQ_BC_Assessments UNIQUE (building_no, unit_number, [year]),
    FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE pm.TAXES (
    tax_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    municipal_eht DECIMAL(10,2),
    bc_speculation_tax DECIMAL(10,2),
    federal_uht DECIMAL(10,2),
    FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE pm.BUILDING_MANAGERS (
    manager_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    name NVARCHAR(100),
    phone NVARCHAR(50),
    email NVARCHAR(255),
    concierge_desk NVARCHAR(100),
    concierge_phone NVARCHAR(50),
    concierge_email NVARCHAR(255),
    FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE pm.STRATA_MANAGERS (
    strata_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    strata_number NVARCHAR(50),
    strata_lot NVARCHAR(50),
    manager_name NVARCHAR(100),
    contact_number NVARCHAR(50),
    email NVARCHAR(255),
    FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
    -- original diagram showed note about (building_no, unit_number); using property_id FK is consistent with surrogate-key model
);

CREATE TABLE pm.KEYS_FOBS_BUZZER (
    key_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    keys NVARCHAR(50),
    fobs NVARCHAR(50),
    buzzer_no NVARCHAR(50),
    FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- 7 Utilities (bills + split by payer)
------------------------------------------------------------
CREATE TABLE pm.UTILITIES (
    utility_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    utype_id INT NOT NULL,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (utype_id)   REFERENCES pm.UTILITY_TYPE(utype_id)
);

CREATE TABLE pm.UTILITY_SPLIT (
    split_id INT IDENTITY(1,1) PRIMARY KEY,
    payer_id INT NOT NULL,
    utility_id INT NOT NULL,
    percentage DECIMAL(5,2),
    amount DECIMAL(10,2), -- (total_amount * % / 100)
    FOREIGN KEY (payer_id)  REFERENCES pm.UTILITY_PAYER(payer_id),
    FOREIGN KEY (utility_id) REFERENCES pm.UTILITIES(utility_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- 8 Contractors & maintenance
------------------------------------------------------------
CREATE TABLE pm.CONTRACTORS (
    contractor_id INT IDENTITY(1,1) PRIMARY KEY,
    company_name NVARCHAR(150),
    contact_name NVARCHAR(100),
    contact_number NVARCHAR(50),
    email NVARCHAR(255),
    services_provided NVARCHAR(255),
    specialization NVARCHAR(100),
    notes NVARCHAR(255)
);

CREATE TABLE pm.MAINTENANCE (
    maintenance_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    contractor_id INT NULL,
    description NVARCHAR(255),
    action_plan NVARCHAR(255),
    status NVARCHAR(50),
    assigned_to NVARCHAR(100),
    FOREIGN KEY (property_id)  REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (contractor_id) REFERENCES pm.CONTRACTORS(contractor_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

------------------------------------------------------------
-- 9 Speculation notices
------------------------------------------------------------
CREATE TABLE pm.BC_SPECULATION_NOTICES (
    notice_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    owner_first_name NVARCHAR(255),
    owner_last_name  NVARCHAR(255),
    owner_email NVARCHAR(255),
    notice NVARCHAR(500) NULL, -- can be NULL or hold notes
    year_of_notice INT NOT NULL,
    CONSTRAINT UQ_NOTICE UNIQUE (notice, year_of_notice),
    FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- 10 Rent history
------------------------------------------------------------
CREATE TABLE pm.RENT (
    rent_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    rent_year INT NOT NULL,
    rent_amount DECIMAL(10,2),
    effective_date DATE,
    end_date DATE,
    notes NVARCHAR(255),
    CONSTRAINT UQ_Rent_Properties UNIQUE (effective_date, property_id),
    FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
