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
IF OBJECT_ID('pm.PROPERTIES','U') IS NOT NULL
    DROP TABLE pm.PROPERTIES;
GO
CREATE TABLE pm.PROPERTIES
(
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    unit_type NVARCHAR(100),
    address NVARCHAR(255),
    city NVARCHAR(100),
    province NVARCHAR(100),
    postal_code NVARCHAR(20),
    management_start_date DATE,
    length_of_service NVARCHAR(50),
    status NVARCHAR(50),
    security_deposit DECIMAL(10,2),
    security_deposit_date DATE,
    pet_deposit DECIMAL(10,2),
    storage_locker NVARCHAR(50),
    parking_stall NVARCHAR(50),
    remarks NVARCHAR(500),
    CONSTRAINT PK_PROPERTIES PRIMARY KEY (building_no, unit_number)
);
GO
CREATE INDEX IX_PROPERTIES_building_unit
    ON pm.PROPERTIES(building_no, unit_number);
GO

-- ==============================================================
-- 2) TENANTS (Normalized)
-- ==============================================================
IF OBJECT_ID('pm.TENANTS','U') IS NOT NULL
    DROP TABLE pm.TENANTS;
GO
CREATE TABLE pm.TENANTS
(
    tenant_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    first_name NVARCHAR(100),
    last_name NVARCHAR(100),
    email NVARCHAR(255),
    mobile NVARCHAR(50),
    lease_start_date DATE,
    lease_end_date DATE,
    lease_status NVARCHAR(50),
    term NVARCHAR(50),
    last_rent_increase DATE,
    CONSTRAINT FK_Tenants_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_TENANTS_building_unit
    ON pm.TENANTS(building_no, unit_number);
GO

-- ==============================================================
-- 3) OWNERS
-- ==============================================================
IF OBJECT_ID('pm.OWNERS','U') IS NOT NULL
    DROP TABLE pm.OWNERS;
GO
CREATE TABLE pm.OWNERS
(
    owner_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    owner_name_1 NVARCHAR(100),
    owner_name_2 NVARCHAR(100),
    type_of_owner NVARCHAR(50),
    owner_number_1 NVARCHAR(50),
    owner_email_1 NVARCHAR(255),
    owner_email_2 NVARCHAR(255),
    CONSTRAINT FK_Owners_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_OWNERS_building_unit
    ON pm.OWNERS(building_no, unit_number);
GO

-- ==============================================================
-- 4) RENT (Normalized)
-- ==============================================================
IF OBJECT_ID('pm.RENT','U') IS NOT NULL
    DROP TABLE pm.RENT;
GO
CREATE TABLE pm.RENT
(
    rent_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    rent_year INT NOT NULL,
    rent_amount DECIMAL(10,2),
    effective_date DATE,
    end_date DATE,
    notes NVARCHAR(255),
    CONSTRAINT FK_Rent_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_RENT_building_unit_year
    ON pm.RENT(building_no, unit_number, rent_year);
GO

-- ==============================================================
-- 5) BC ASSESSMENTS (New)
-- ==============================================================
IF OBJECT_ID('pm.BC_ASSESSMENTS','U') IS NOT NULL
    DROP TABLE pm.BC_ASSESSMENTS;
GO
CREATE TABLE pm.BC_ASSESSMENTS
(
    assessment_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    [year] INT NOT NULL,
    assessed_value DECIMAL(12,2),
    CONSTRAINT FK_BC_Assessments_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_BC_ASSESSMENTS_building_unit_year
    ON pm.BC_ASSESSMENTS(building_no, unit_number, [year]);
GO

-- ==============================================================
-- 6) INSPECTIONS (With Follow-Up)
-- ==============================================================
IF OBJECT_ID('pm.INSPECTIONS','U') IS NOT NULL
    DROP TABLE pm.INSPECTIONS;
GO
CREATE TABLE pm.INSPECTIONS
(
    inspection_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    last_inspection_date DATE,
    need_inspection NVARCHAR(50),
    inspection_type NVARCHAR(100),
    inspection_notes NVARCHAR(500),
    repairs_maintenance NVARCHAR(255),
    follow_up_date DATE NULL,
    CONSTRAINT FK_Inspections_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_INSPECTIONS_building_unit
    ON pm.INSPECTIONS(building_no, unit_number);
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
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    contractor_id INT,
    description NVARCHAR(255),
    action_plan NVARCHAR(255),
    status NVARCHAR(50),
    assigned_to NVARCHAR(100),
    CONSTRAINT FK_Maintenance_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_Maintenance_Contractors FOREIGN KEY (contractor_id)
        REFERENCES pm.CONTRACTORS(contractor_id)
);
GO
CREATE INDEX IX_MAINTENANCE_building_unit
    ON pm.MAINTENANCE(building_no, unit_number);
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
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    municipal_eht DECIMAL(10,2),
    bc_speculation_tax DECIMAL(10,2),
    federal_uht DECIMAL(10,2),
    CONSTRAINT FK_Taxes_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_TAXES_building_unit
    ON pm.TAXES(building_no, unit_number);
GO

-- ==============================================================
-- 10) UTILITIES
-- ==============================================================
IF OBJECT_ID('pm.UTILITIES','U') IS NOT NULL
    DROP TABLE pm.UTILITIES;
GO
CREATE TABLE pm.UTILITIES
(
    utility_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    upper_or_lower NVARCHAR(50),
    percent_split DECIMAL(5,2),
    bc_hydro DECIMAL(10,2),
    fortis_bc DECIMAL(10,2),
    CONSTRAINT FK_Utilities_Properties FOREIGN KEY
    (building_no, unit_number)
        REFERENCES pm.PROPERTIES
    (building_no, unit_number)
        ON
    UPDATE CASCADE ON
    DELETE CASCADE
);
GO
CREATE INDEX IX_UTILITIES_building_unit
    ON pm.UTILITIES(building_no, unit_number);
GO

-- ==============================================================
-- 11) MOVE IN / OUT
-- ==============================================================
IF OBJECT_ID('pm.MOVE_IN_OUT','U') IS NOT NULL
    DROP TABLE pm.MOVE_IN_OUT;
GO
CREATE TABLE pm.MOVE_IN_OUT
(
    move_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    tenant_id INT NULL,
    move_type NVARCHAR(50),
    tenant_name NVARCHAR(150),
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
    CONSTRAINT FK_MoveInOut_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_MOVEINOUT_building_unit
    ON pm.MOVE_IN_OUT(building_no, unit_number);
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
-- 15) TENANT INSURANCE (Azure-safe)
-- ==============================================================
IF OBJECT_ID('pm.TENANT_INSURANCE','U') IS NOT NULL
    DROP TABLE pm.TENANT_INSURANCE;
GO
CREATE TABLE pm.TENANT_INSURANCE
(
    insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    tenant_id INT NULL,
    -- logical reference only (no FK to avoid cascade cycle)
    policy_number NVARCHAR(100),
    start_date DATE,
    end_date DATE,
    remarks NVARCHAR(255),
    CONSTRAINT FK_TenantInsurance_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_TENANT_INSURANCE_building_unit
    ON pm.TENANT_INSURANCE(building_no, unit_number);
GO

-- ==============================================================
-- 16) OWNER INSURANCE (Azure-safe)
-- ==============================================================
IF OBJECT_ID('pm.OWNER_INSURANCE','U') IS NOT NULL
    DROP TABLE pm.OWNER_INSURANCE;
GO
CREATE TABLE pm.OWNER_INSURANCE
(
    insurance_id INT IDENTITY(1,1) PRIMARY KEY,
    building_no NVARCHAR(50) NOT NULL,
    unit_number NVARCHAR(50) NOT NULL,
    owner_id INT NULL,
    -- logical reference only (no FK to avoid cascade cycle)
    insurance_number NVARCHAR(100),
    start_date DATE,
    end_date DATE,
    remarks NVARCHAR(255),
    CONSTRAINT FK_OwnerInsurance_Properties FOREIGN KEY (building_no, unit_number)
        REFERENCES pm.PROPERTIES(building_no, unit_number)
        ON UPDATE CASCADE ON DELETE CASCADE
);
GO
CREATE INDEX IX_OWNER_INSURANCE_building_unit
    ON pm.OWNER_INSURANCE(building_no, unit_number);
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
