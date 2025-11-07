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
IF OBJECT_ID('pm.PROPERTIES', 'U') IS NOT NULL
    DROP TABLE pm.PROPERTIES;
GO
IF OBJECT_ID('pm.PROPERTY_TYPE', 'U') IS NOT NULL
    DROP TABLE pm.PROPERTY_TYPE;
GO
IF OBJECT_ID('pm.CITY', 'U') IS NOT NULL
    DROP TABLE pm.CITY;
GO
IF OBJECT_ID('pm.PROVINCE', 'U') IS NOT NULL
    DROP TABLE pm.PROVINCE;
GO

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
    unit_type INT,
    address NVARCHAR(255),
    postal_code NVARCHAR(20),
    management_start_date DATE,
    length_of_service NVARCHAR(50),
    status NVARCHAR(50),
    storage_locker NVARCHAR(50),
    parking_stall NVARCHAR(50),
    remarks NVARCHAR(500),
    city_id INT,
    province_id INT,
    
    CONSTRAINT UQ_PROPERTIES UNIQUE (building_no, unit_number),
    
    CONSTRAINT FK_PROPERTIES_UNIT_TYPE FOREIGN KEY (unit_type)
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
    ON pm.PROPERTIES(unit_type);

CREATE INDEX IX_PROPERTIES_CITY
    ON pm.PROPERTIES(city_id);

CREATE INDEX IX_PROPERTIES_PROVINCE
    ON pm.PROPERTIES(province_id);


-- ==============================================================
-- 2) TENANTS (Normalized)
-- ==============================================================
IF OBJECT_ID('pm.TENANCY', 'U') IS NOT NULL
    DROP TABLE pm.TENANCY;
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


IF OBJECT_ID('pm.TENANT_INSURANCE', 'U') IS NOT NULL
    DROP TABLE pm.TENANT_INSURANCE;
GO

CREATE TABLE pm.TENANT_INSURANCE
(
    insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    policy_number NVARCHAR(100),
    insurance_start_date DATE,
    insurance_end_date DATE,
    remarks NVARCHAR(255)
);
GO

CREATE INDEX IX_TENANT_INSURANCE_POLICY
    ON pm.TENANT_INSURANCE(policy_number);



IF OBJECT_ID('pm.TENANT', 'U') IS NOT NULL
    DROP TABLE pm.TENANT;
GO

CREATE TABLE pm.TENANT
(
    tenant_id INT IDENTITY(1,1) PRIMARY KEY,  
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    phone_number NVARCHAR(20) NULL,
    email NVARCHAR(150) NULL
);
GO

-- Index on email or phone for quick lookups
CREATE INDEX IX_TENANT_EMAIL
    ON pm.TENANT(email);

CREATE INDEX IX_TENANT_PHONE
    ON pm.TENANT(phone_number);



-- ==============================================================
-- 3) OWNERS
-- ==============================================================
IF OBJECT_ID('pm.OWNERS','U') IS NOT NULL
    DROP TABLE pm.OWNERS;
GO
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



IF OBJECT_ID('pm.CARE_OF', 'U') IS NOT NULL
    DROP TABLE pm.CARE_OF;
GO

CREATE TABLE pm.CARE_OF
(
    care_of_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(100),
    last_name NVARCHAR(100),
    phone_number NVARCHAR(50),
    email NVARCHAR(255)
    
);
GO

IF OBJECT_ID('pm.OWNER_INSURANCE', 'U') IS NOT NULL
    DROP TABLE pm.OWNER_INSURANCE;
GO

CREATE TABLE pm.OWNER_INSURANCE
(
    owner_insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    policy_number NVARCHAR(100),
    insurance_start_date DATE,
    insurance_end_date DATE,
    remarks NVARCHAR(255)
);
GO

CREATE INDEX IX_OWNER_INSURANCE_POLICY
    ON pm.OWNER_INSURANCE(policy_number);


IF OBJECT_ID('pm.OWNERSHIP', 'U') IS NOT NULL
    DROP TABLE pm.OWNERSHIP;
GO

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
-- 4) RENT
-- ==============================================================
IF OBJECT_ID('pm.RENT','U') IS NOT NULL
    DROP TABLE pm.RENT;
GO

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
IF OBJECT_ID('pm.BC_ASSESSMENTS','U') IS NOT NULL  
    DROP TABLE pm.BC_ASSESSMENTS;  
GO  

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
IF OBJECT_ID('pm.INSPECTION_TYPE','U') IS NOT NULL
    DROP TABLE pm.INSPECTION_TYPE;
GO

CREATE TABLE pm.INSPECTION_TYPE
(
    inspection_type_id INT IDENTITY(1,1) PRIMARY KEY,
    inspection_type NVARCHAR(100) NOT NULL
);
GO

IF OBJECT_ID('pm.INSPECTIONS','U') IS NOT NULL
    DROP TABLE pm.INSPECTIONS;
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

IF OBJECT_ID('pm.INSPECTION_ISSUES','U') IS NOT NULL
    DROP TABLE pm.INSPECTION_ISSUES;
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
IF OBJECT_ID('pm.CONTRACTORS','U') IS NOT NULL  
    DROP TABLE pm.CONTRACTORS;  
GO  
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
IF OBJECT_ID('pm.MAINTENANCE','U') IS NOT NULL  
    DROP TABLE pm.MAINTENANCE;  
GO  
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
IF OBJECT_ID('pm.TAXES','U') IS NOT NULL
    DROP TABLE pm.TAXES;
GO
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
IF OBJECT_ID('pm.UTILITIES','U') IS NOT NULL
    DROP TABLE pm.UTILITIES;
GO
CREATE TABLE pm.UTILITIES
(
    utility_id INT IDENTITY(1,1) PRIMARY KEY,
    
    property_id INT,
    utype_id INT,
    total_amount DECIMAL(10,2),

    CONSTRAINT FK_PROPERTY_UTILITIEs FOREIGN KEY(property_id)
        REFERENCES pm.property(property_id),
    CONSTRAINT FK_UTYPE_UTILITIEs FOREIGN KEY(utype_id)
        REFERENCES pm.UTILITY_TYPE(utype_id)
);
GO
IF OBJECT_ID('pm.UTILITY_TYPE','U') IS NOT NULL
    DROP TABLE pm.UTILITY_TYPE;
GO
CREATE TABLE pm.UTILITY_TYPE
(
    utype_id INT IDENTITY(1,1),
    utility_name VARCHAR(25)
);

IF OBJECT_ID('pm.UTILITY_SPLIT', 'U') IS NOT NULL
    DROP TABLE pm.UTILITY_SPLIT;
GO

CREATE TABLE pm.UTILITY_SPLIT
(
    split_id INT IDENTITY(1,1) PRIMARY KEY,
    payer_id INT NOT NULL,
    utility_id INT NOT NULL,
    percentage DECIMAL(5,2) NOT NULL,
    amount AS (total_amount * percentage / 100.0) PERSISTED,
    
    CONSTRAINT FK_UTILITY_SPLIT_PAYER
    FOREIGN KEY (payer_id) REFERENCES pm.UTILITY_PAYER(payer_id),

    CONSTRAINT FK_UTILITY_SPLIT_UTILITY
    FOREIGN KEY (utility_id) REFERENCES pm.UTILITIES(utility_id)

);


IF OBJECT_ID('pm.UTILITY_PAYER','U') IS NOT NULL
    DROP TABLE pm.UTILITY_PAYER;
GO
CREATE TABLE pm.UTILITY_PAYER
(
    payer_id INT IDENTITY(1,1) PRIMARY KEY,
    payer VARCHAR(6)
);


-- ==============================================================
-- 11) MOVE IN / OUT 
-- ==============================================================
IF OBJECT_ID('pm.MOVE_IN_OUT','U') IS NOT NULL
    DROP TABLE pm.MOVE_IN_OUT;
GO
CREATE TABLE pm.MOVE_IN_OUT
(
    move_id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id INT NOT NULL,
    move_type NVARCHAR(50),  -- 'Move In' or 'Move Out'
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
    CONSTRAINT FK_MoveInOut_Tenants FOREIGN KEY (tenant_id)
        REFERENCES pm.TENANTS(tenant_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_MOVEINOUT_tenant_id
    ON pm.MOVE_IN_OUT(tenant_id);
GO
CREATE INDEX IX_MOVEINOUT_move_date
    ON pm.MOVE_IN_OUT(move_date);  
GO

-- ==============================================================
-- 12) BUILDING MANAGERS
-- ==============================================================
IF OBJECT_ID('pm.BUILDING_MANAGERS','U') IS NOT NULL
    DROP TABLE pm.BUILDING_MANAGERS;
GO
CREATE TABLE pm.BUILDING_MANAGERS
(
    manager_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    name NVARCHAR(100),
    phone NVARCHAR(50),
    email NVARCHAR(255),
    concierge_desk NVARCHAR(100),
    concierge_phone NVARCHAR(50),
    concierge_email NVARCHAR(255),
    CONSTRAINT FK_BuildingManagers_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_BUILDING_MANAGERS_building_unit
    ON pm.BUILDING_MANAGERS(building_no, unit_number);
GO

-- ==============================================================
-- 13) STRATA MANAGERS
-- ==============================================================
IF OBJECT_ID('pm.STRATA_MANAGERS','U') IS NOT NULL
    DROP TABLE pm.STRATA_MANAGERS;
GO
CREATE TABLE pm.STRATA_MANAGERS
(
    strata_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    strata_number NVARCHAR(50),
    strata_lot NVARCHAR(50),
    manager_name NVARCHAR(100),
    contact_number NVARCHAR(50),
    email NVARCHAR(255),
    CONSTRAINT FK_StrataManagers_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_STRATA_MANAGERS_building_unit
    ON pm.STRATA_MANAGERS(building_no, unit_number);
GO

-- ==============================================================
-- 14) KEYS / FOBS
-- ==============================================================
IF OBJECT_ID('pm.KEYS_FOBS','U') IS NOT NULL
    DROP TABLE pm.KEYS_FOBS;
GO
CREATE TABLE pm.KEYS_FOBS
(
    key_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    keys NVARCHAR(50),
    fobs NVARCHAR(50),
    buzzer_no NVARCHAR(50),
    CONSTRAINT FK_KeysFobs_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_KEYSFOBS_building_unit
    ON pm.KEYS_FOBS(building_no, unit_number);
GO

-- ==============================================================
-- 15) TENANT INSURANCE (Corrected)
-- ==============================================================
IF OBJECT_ID('pm.TENANT_INSURANCE','U') IS NOT NULL
    DROP TABLE pm.TENANT_INSURANCE;
GO
CREATE TABLE pm.TENANT_INSURANCE
(
    insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id INT NOT NULL,
    policy_number NVARCHAR(100),
    start_date DATE,
    end_date DATE,
    remarks NVARCHAR(255),
    CONSTRAINT FK_TenantInsurance_Tenants FOREIGN KEY (tenant_id)
        REFERENCES pm.TENANTS(tenant_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_TENANT_INSURANCE_tenant_id
    ON pm.TENANT_INSURANCE(tenant_id);
GO

-- ==============================================================
-- 16) OWNER INSURANCE (Corrected)
-- ==============================================================
IF OBJECT_ID('pm.OWNER_INSURANCE','U') IS NOT NULL
    DROP TABLE pm.OWNER_INSURANCE;
GO
CREATE TABLE pm.OWNER_INSURANCE
(
    insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    owner_id INT NOT NULL,
    insurance_number NVARCHAR(100),
    start_date DATE,
    end_date DATE,
    remarks NVARCHAR(255),
    CONSTRAINT FK_OwnerInsurance_Owners FOREIGN KEY (owner_id)
        REFERENCES pm.OWNERS(owner_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_OWNER_INSURANCE_owner_id
    ON pm.OWNER_INSURANCE(owner_id);
GO

-- ==============================================================
-- 17) INSPECTION ISSUES (Finalized Design)
-- ==============================================================
IF OBJECT_ID('pm.INSPECTION_ISSUES','U') IS NOT NULL
    DROP TABLE pm.INSPECTION_ISSUES;
GO
CREATE TABLE pm.INSPECTION_ISSUES
(
    issue_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NULL,
    description_of_issue NVARCHAR(MAX),
    action_plan NVARCHAR(MAX),
    checked_off_by NVARCHAR(100),
    -- corresponds to "C/O" (Aleks)
    status NVARCHAR(100),
    date_logged DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_InspectionIssues_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_INSPECTION_ISSUES_building_unit
    ON pm.INSPECTION_ISSUES(building_no, unit_number);
GO

-- ==============================================================
-- 18) BC SPECULATION TAX NOTICES (Denormalized - Matches Excel)
-- ==============================================================
IF OBJECT_ID('pm.BC_SPECULATION_NOTICES','U') IS NOT NULL
    DROP TABLE pm.BC_SPECULATION_NOTICES;
GO
CREATE TABLE pm.BC_SPECULATION_NOTICES
(
    notice_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    owner_name NVARCHAR(255),
    owner_email_1 NVARCHAR(255),
    owner_email_2 NVARCHAR(255),
    notice_2025 NVARCHAR(500),  -- Can be NULL or contain notes
    notice_2024 NVARCHAR(500),  -- Can be NULL or contain notes
    notice_2023 NVARCHAR(500)   -- Can be NULL or contain notes
);
GO
CREATE INDEX IX_BC_SPECULATION_building
    ON pm.BC_SPECULATION_NOTICES(building_no);
GO