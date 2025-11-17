-- ==============================================================
-- Property Management Database (Normalized & CSV-Aligned)
-- ==============================================================

-- Cleanup block for iterative dev in Azure SQL
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'';
    SELECT @sql += 'ALTER TABLE [' + SCHEMA_NAME(fk.schema_id) + '].[' + OBJECT_NAME(fk.parent_object_id) + '] DROP CONSTRAINT [' + fk.name + '];'
    FROM sys.foreign_keys fk
    WHERE SCHEMA_NAME(fk.schema_id) = 'pm';
    EXEC sp_executesql @sql;
END
GO

-- ==============================================================
-- 1) PROPERTIES
-- ==============================================================
CREATE TABLE pm.PROVINCE
(
    province_id INT IDENTITY(1,1) PRIMARY KEY,
    province NVARCHAR(100)
);
GO

CREATE TABLE pm.CITY
(
    city_id INT IDENTITY(1,1) PRIMARY KEY,
    city NVARCHAR(100)
);
GO

CREATE TABLE pm.PROPERTY_TYPE
(
    unit_type_id INT IDENTITY(1,1) PRIMARY KEY,
    unit_type NVARCHAR(100)
);
GO

CREATE TABLE pm.PROPERTIES
(
    property_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    unit_type_id INT,
    address NVARCHAR(255),
    postal_code NVARCHAR(20),
    management_start_date DATE,
    length_of_service NVARCHAR(50),
    status NVARCHAR(50),
    storage_locker NVARCHAR(100),
    parking_stall NVARCHAR(50),
    remarks NVARCHAR(500),
    city_id INT,
    province_id INT,
    
    CONSTRAINT UQ_PROPERTIES UNIQUE (building_no, unit_number),
    
    CONSTRAINT FK_PROPERTIES_UNIT_TYPE FOREIGN KEY (unit_type_id)
        REFERENCES pm.PROPERTY_TYPE(unit_type_id),
        
    CONSTRAINT FK_PROPERTIES_CITY FOREIGN KEY (city_id)
        REFERENCES pm.CITY(city_id),
        
    CONSTRAINT FK_PROPERTIES_PROVINCE FOREIGN KEY (province_id)
        REFERENCES pm.PROVINCE(province_id)
);
GO

CREATE UNIQUE INDEX IX_PROPERTIES_BUILDING_UNIT
    ON pm.PROPERTIES(building_no, unit_number);

CREATE INDEX IX_PROPERTIES_UNIT_TYPE
    ON pm.PROPERTIES(unit_type_id);

CREATE INDEX IX_PROPERTIES_CITY
    ON pm.PROPERTIES(city_id);

CREATE INDEX IX_PROPERTIES_PROVINCE
    ON pm.PROPERTIES(province_id);


-- ==============================================================
-- 2) TENANTS (Normalized)
-- ==============================================================

CREATE TABLE pm.TENANT_INSURANCE
(
    insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    policy_number NVARCHAR(100),
    insurance_start_date DATE,
    insurance_end_date DATE,
    remarks NVARCHAR(255)
);
GO



CREATE TABLE pm.TENANCY
(
    tenancy_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    insurance_id INT NULL,
    lease_start_date DATE NOT NULL,
    lease_end_date DATE NULL,
    lease_status NVARCHAR(50),
    term NVARCHAR(50),
    last_rent_increase DATE,
    security_deposit DECIMAL(10,2),
    security_deposit_date DATE,
    pet_deposit DECIMAL(10,2),
    pet_deposit_date DATE,

    CONSTRAINT UQ_TENANCY_PROPERTY UNIQUE (property_id, lease_start_date),

    CONSTRAINT FK_TENANCY_PROPERTY FOREIGN KEY (property_id)
        REFERENCES pm.PROPERTIES (property_id),

    CONSTRAINT FK_TENANCY_INSURANCE FOREIGN KEY (insurance_id)
        REFERENCES pm.TENANT_INSURANCE (insurance_id)
);
GO
CREATE TABLE pm.TENANT
(
    tenancy_id INT NULL,
    tenant_id INT IDENTITY(1,1) PRIMARY KEY,  
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    phone_number NVARCHAR(20) NULL,
    email NVARCHAR(150) NULL

    CONSTRAINT FK_TENANCY_TENANT FOREIGN KEY (tenancy_id)
    REFERENCES pm.TENANCY (tenancy_id)
);
GO

-- Index on email or phone for quick lookups
CREATE INDEX IX_TENANT_EMAIL
    ON pm.TENANT(email);

CREATE INDEX IX_TENANT_PHONE
    ON pm.TENANT(phone_number);

CREATE INDEX IX_TENANT_INSURANCE_POLICY
    ON pm.TENANT_INSURANCE(policy_number);



-- ==============================================================
-- 3) OWNERS
-- ==============================================================


CREATE TABLE pm.CARE_OF
(
    care_of_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(100),
    last_name NVARCHAR(100),
    phone_number NVARCHAR(50),
    email NVARCHAR(255)
    
);
GO

CREATE TABLE pm.OWNER_INSURANCE
(
    property_id INT,
    owner_insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    policy_number NVARCHAR(100),
    insurance_start_date DATE,
    insurance_end_date DATE,
    remarks NVARCHAR(255)

    CONSTRAINT FK_PROPERTY_INSURANCE FOREIGN KEY (property_id)
    REFERENCES pm.PROPERTIES (property_id)
);
GO

CREATE INDEX IX_OWNER_INSURANCE_POLICY
    ON pm.OWNER_INSURANCE(policy_number);


CREATE TABLE pm.OWNERS
(
    owner_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(100),
    last_name NVARCHAR(100),
    company_name NVARCHAR(100),
    type_of_owner NVARCHAR(50),
    phone_number NVARCHAR(50),
    email NVARCHAR(255),
    care_of INT,

    CONSTRAINT FK_CARE_OF FOREIGN KEY (care_of)
        REFERENCES pm.CARE_OF (care_of_id)

);
GO

CREATE INDEX IX_OWNERS_CARE_OF
    ON pm.OWNERS(care_of);

CREATE INDEX IX_OWNERS_EMAIL
    ON pm.OWNERS(email);

CREATE TABLE pm.OWNERSHIP
(
    ownership_id INT IDENTITY(1,1) PRIMARY KEY,
    frn_owner_id INT NOT NULL,
    frn_property_id INT NOT NULL,

    CONSTRAINT FK_OWNERSHIP_OWNER FOREIGN KEY (frn_owner_id)
        REFERENCES pm.OWNERS (owner_id),

    CONSTRAINT FK_OWNERSHIP_PROPERTY FOREIGN KEY (frn_property_id)
        REFERENCES pm.PROPERTIES (property_id)
);
GO

CREATE INDEX IX_OWNERSHIP_OWNER
    ON pm.OWNERSHIP(frn_owner_id);

CREATE INDEX IX_OWNERSHIP_PROPERTY
    ON pm.OWNERSHIP(frn_property_id);
-- ==============================================================
-- 4) RENT TABLE
-- ==============================================================

CREATE TABLE pm.RENT
(
    rent_id INT IDENTITY(1,1) PRIMARY KEY,       
    property_id INT NOT NULL,                     
    rent_year INT NOT NULL,
    rent_amount DECIMAL(10,2),
    effective_date DATE NOT NULL,
    end_date DATE NULL,
    notes NVARCHAR(255) NULL,

    CONSTRAINT UQ_RENT_PROPERTY_EFFECTIVE UNIQUE (property_id, effective_date),

    CONSTRAINT FK_RENT_PROPERTY FOREIGN KEY (property_id)
        REFERENCES pm.PROPERTIES(property_id)
);
GO

CREATE INDEX IX_RENT_PROPERTY_YEAR
    ON pm.RENT(property_id, rent_year);
GO


-- ==============================================================  
-- 5) BC ASSESSMENTS  
-- ==============================================================  


CREATE TABLE pm.BC_ASSESSMENTS
(
    assessment_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    [year] INT NOT NULL,
    assessed_value DECIMAL(12,2),

    CONSTRAINT UQ_BC_ASSESSMENTS_PROPERTY_YEAR UNIQUE (property_id, [year]),

    CONSTRAINT FK_BC_ASSESSMENTS_PROPERTY FOREIGN KEY (property_id)
        REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO

CREATE INDEX IX_BC_ASSESSMENTS_PROPERTY_YEAR
    ON pm.BC_ASSESSMENTS(property_id, [year]);
GO

-- ==============================================================
-- 6) INSPECTIONS
-- ==============================================================


CREATE TABLE pm.INSPECTION_TYPE
(
    inspection_type_id INT IDENTITY(1,1) PRIMARY KEY,
    inspection_type NVARCHAR(100) NOT NULL
);
GO



CREATE TABLE pm.INSPECTIONS
(
    inspection_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    inspection_type_id INT NOT NULL,
    last_inspection_date DATE,
    need_inspection NVARCHAR(50),
    inspection_notes NVARCHAR(500),
    repairs_maintenance NVARCHAR(255),
    follow_up_date DATE NULL,

    -- Foreign keys
    CONSTRAINT FK_INSPECTIONS_PROPERTY FOREIGN KEY (property_id)
        REFERENCES pm.PROPERTIES(property_id),

    CONSTRAINT FK_INSPECTIONS_TYPE FOREIGN KEY (inspection_type_id)
        REFERENCES pm.INSPECTION_TYPE(inspection_type_id)
);
GO

-- Optional index for faster queries by property
CREATE INDEX IX_INSPECTIONS_PROPERTY
    ON pm.INSPECTIONS(property_id);
GO



CREATE TABLE pm.INSPECTION_ISSUES
(
    issue_id INT IDENTITY(1,1) PRIMARY KEY,
    inspection_id INT NOT NULL,
    description_of_issue NVARCHAR(500),
    action_plan NVARCHAR(500),
    checked_off_by NVARCHAR(100),
    status NVARCHAR(50),
    date_logged DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_INSPECTION_ISSUES_INSPECTION FOREIGN KEY (inspection_id)
        REFERENCES pm.INSPECTIONS(inspection_id)
);
GO

-- Optional index for faster queries by inspection
CREATE INDEX IX_INSPECTION_ISSUES_INSPECTION
    ON pm.INSPECTION_ISSUES(inspection_id);
GO

-- ==============================================================  
-- 7) CONTRACTORS  
-- ==============================================================  

CREATE TABLE pm.CONTRACTORS  
(  
    contractor_id INT IDENTITY(1,1) PRIMARY KEY,  
    company_name NVARCHAR(150),  
    contact_name NVARCHAR(100),  
    contact_number NVARCHAR(50),  
    email NVARCHAR(255),  
    services_provided NVARCHAR(255),  
    specialization NVARCHAR(100),  
    notes NVARCHAR(255)  
);  
GO  
  
-- ==============================================================  
-- 8) MAINTENANCE  
-- ==============================================================  

CREATE TABLE pm.MAINTENANCE  
(  
    maintenance_id INT IDENTITY(1,1) PRIMARY KEY,  
    property_id INT NOT NULL,  
    contractor_id INT NOT NULL,  
    description NVARCHAR(255),  
    action_plan NVARCHAR(255),  
    status NVARCHAR(50),  
    assigned_to NVARCHAR(100),  
  
    CONSTRAINT FK_MAINTENANCE_PROPERTY FOREIGN KEY (property_id)  
        REFERENCES pm.PROPERTIES(property_id),  
  
    CONSTRAINT FK_MAINTENANCE_CONTRACTOR FOREIGN KEY (contractor_id)  
        REFERENCES pm.CONTRACTORS(contractor_id)  
);  
GO  
  
CREATE INDEX IX_MAINTENANCE_PROPERTY_CONTRACTOR  
    ON pm.MAINTENANCE(property_id, contractor_id);  
GO

-- ==============================================================
-- 9) TAXES
-- ==============================================================

CREATE TABLE pm.TAXES
(
    tax_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT,
    municipal_eht DECIMAL(10,2),
    bc_speculation_tax DECIMAL(10,2),
    federal_uht DECIMAL(10,2),
    CONSTRAINT FK_TAX_PROPERTY FOREIGN KEY (property_id)  
        REFERENCES pm.PROPERTIES(property_id)  
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_TAXES_building_unit
    ON pm.TAXES(property_id);
GO

-- ==============================================================
-- 10) UTILITIES (Fixed - No Cascade Cycle)
-- ==============================================================

CREATE TABLE pm.UTILITY_PAYER
(
    payer_id INT IDENTITY(1,1) PRIMARY KEY,
    payer VARCHAR(6)
);

CREATE TABLE pm.UTILITY_TYPE
(
    utype_id INT IDENTITY(1,1) PRIMARY KEY,
    utility_name VARCHAR(25)
);


CREATE TABLE pm.UTILITIES
(
    utility_id INT IDENTITY(1,1) PRIMARY KEY,
    
    property_id INT,
    utype_id INT,
    total_amount DECIMAL(10,2),

    CONSTRAINT FK_PROPERTY_UTILITIEs FOREIGN KEY(property_id)
        REFERENCES pm.PROPERTIES(property_id),
    CONSTRAINT FK_UTYPE_UTILITIEs FOREIGN KEY(utype_id)
        REFERENCES pm.UTILITY_TYPE(utype_id)
);
GO

CREATE TABLE pm.UTILITY_SPLIT
(
    split_id INT IDENTITY(1,1) PRIMARY KEY,
    payer_id INT NOT NULL,
    utility_id INT NOT NULL,
    percentage DECIMAL(5,2) NOT NULL
    
    CONSTRAINT FK_UTILITY_SPLIT_PAYER
    FOREIGN KEY (payer_id) REFERENCES pm.UTILITY_PAYER(payer_id),

    CONSTRAINT FK_UTILITY_SPLIT_UTILITY
    FOREIGN KEY (utility_id) REFERENCES pm.UTILITIES(utility_id)

);



-- ==============================================================
-- 11) MOVE IN / OUT 
-- ==============================================================

CREATE TABLE pm.MOVE_TYPE (
    move_type_id INT IDENTITY(1,1) PRIMARY KEY,
    move_type NVARCHAR(20)
);


CREATE TABLE pm.MOVE (
    move_id INT IDENTITY(1,1) PRIMARY KEY,
    move_type_id INT NOT NULL,
    tenancy_id INT NOT NULL,
    move_date DATE,
    tenant_availability NVARCHAR(50),
    proposed_date_tbc NVARCHAR(50),
    confirmed_with_david NVARCHAR(50),
    status NVARCHAR(50),
    notify_back_office NVARCHAR(50),
    security_release NVARCHAR(50),
    move_out_letter NVARCHAR(50),
    move_in_orientation NVARCHAR(50),
    form_k NVARCHAR(50),
    zinspector NVARCHAR(100),
    FOREIGN KEY (move_type_id) REFERENCES pm.MOVE_TYPE(move_type_id),
    FOREIGN KEY (tenancy_id)   REFERENCES pm.TENANCY(tenancy_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
-- ==============================================================
-- 12) BUILDING MANAGERS
-- ==============================================================

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


-- ==============================================================
-- 13) STRATA MANAGERS
-- ==============================================================

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
);


-- ==============================================================
-- 14) KEYS / FOBS
-- ==============================================================

CREATE TABLE pm.KEYS_FOBS_BUZZER (
    key_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    keys NVARCHAR(50),
    fobs NVARCHAR(50),
    buzzer_no NVARCHAR(50),
    FOREIGN KEY (property_id) REFERENCES pm.PROPERTIES(property_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);


-- ==============================================================
-- 18) BC SPECULATION TAX NOTICES (Denormalized - Matches Excel)
-- ==============================================================

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

CREATE TABLE pm.BC_SPECULATION_NOTICES (
    notice_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    owner_first_name NVARCHAR(255),
    owner_last_name  NVARCHAR(255),
    owner_email NVARCHAR(255),
    company_name NVARCHAR(100),
    notice NVARCHAR(500) NULL, -- can be NULL or hold notes
    year_of_notice INT NOT NULL,
    CONSTRAINT UQ_NOTICE UNIQUE (property_id,notice, year_of_notice),
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