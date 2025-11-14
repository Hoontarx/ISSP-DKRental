-- ==============================================================
-- STORED PROCEDURES FOR MAINTENANCE & INSPECTIONS MANAGEMENT
-- ==============================================================

-- ==============================================================
-- 1. CONTRACTORS MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetAllContractors
    @Specialization NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        contractor_id,
        company_name,
        contact_name,
        contact_number,
        email,
        services_provided,
        specialization,
        notes
    FROM pm.CONTRACTORS
    WHERE
        (@Specialization IS NULL OR specialization LIKE '%' + @Specialization + '%')
    ORDER BY company_name;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetContractorById
    @ContractorId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        contractor_id,
        company_name,
        contact_name,
        contact_number,
        email,
        services_provided,
        specialization,
        notes
    FROM pm.CONTRACTORS
    WHERE contractor_id = @ContractorId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_CreateContractor
    @CompanyName NVARCHAR(150),
    @ContactName NVARCHAR(100) = NULL,
    @ContactNumber NVARCHAR(50) = NULL,
    @Email NVARCHAR(255) = NULL,
    @ServicesProvided NVARCHAR(255) = NULL,
    @Specialization NVARCHAR(100) = NULL,
    @Notes NVARCHAR(255) = NULL,
    @NewContractorId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pm.CONTRACTORS (
        company_name, contact_name, contact_number, email,
        services_provided, specialization, notes
    )
    VALUES (
        @CompanyName, @ContactName, @ContactNumber, @Email,
        @ServicesProvided, @Specialization, @Notes
    );

    SET @NewContractorId = SCOPE_IDENTITY();

    EXEC pm.sp_GetContractorById @NewContractorId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateContractor
    @ContractorId INT,
    @CompanyName NVARCHAR(150) = NULL,
    @ContactName NVARCHAR(100) = NULL,
    @ContactNumber NVARCHAR(50) = NULL,
    @Email NVARCHAR(255) = NULL,
    @ServicesProvided NVARCHAR(255) = NULL,
    @Specialization NVARCHAR(100) = NULL,
    @Notes NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.CONTRACTORS
    SET
        company_name = COALESCE(@CompanyName, company_name),
        contact_name = COALESCE(@ContactName, contact_name),
        contact_number = COALESCE(@ContactNumber, contact_number),
        email = COALESCE(@Email, email),
        services_provided = COALESCE(@ServicesProvided, services_provided),
        specialization = COALESCE(@Specialization, specialization),
        notes = COALESCE(@Notes, notes)
    WHERE contractor_id = @ContractorId;

    EXEC pm.sp_GetContractorById @ContractorId;
END
GO

-- ==============================================================
-- 2. MAINTENANCE MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetMaintenanceRequests
    @PropertyId INT = NULL,
    @Status NVARCHAR(50) = NULL,
    @AssignedTo NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.maintenance_id,
        m.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        m.description,
        m.action_plan,
        m.status,
        m.assigned_to,
        c.company_name AS contractor_company,
        c.contact_name AS contractor_contact,
        c.contact_number AS contractor_phone
    FROM pm.MAINTENANCE m
    INNER JOIN pm.PROPERTIES p ON m.property_id = p.property_id
    LEFT JOIN pm.CONTRACTORS c ON m.contractor_id = c.contractor_id
    WHERE
        (@PropertyId IS NULL OR m.property_id = @PropertyId)
        AND (@Status IS NULL OR m.status = @Status)
        AND (@AssignedTo IS NULL OR m.assigned_to LIKE '%' + @AssignedTo + '%')
    ORDER BY
        CASE
            WHEN m.status = 'Open' THEN 1
            WHEN m.status = 'In Progress' THEN 2
            ELSE 3
        END,
        m.maintenance_id DESC;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetMaintenanceById
    @MaintenanceId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.maintenance_id,
        m.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        m.description,
        m.action_plan,
        m.status,
        m.assigned_to,
        c.contractor_id,
        c.company_name AS contractor_company,
        c.contact_name AS contractor_contact,
        c.contact_number AS contractor_phone
    FROM pm.MAINTENANCE m
    INNER JOIN pm.PROPERTIES p ON m.property_id = p.property_id
    LEFT JOIN pm.CONTRACTORS c ON m.contractor_id = c.contractor_id
    WHERE m.maintenance_id = @MaintenanceId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_CreateMaintenance
    @PropertyId INT,
    @Description NVARCHAR(255),
    @ActionPlan NVARCHAR(255) = NULL,
    @Status NVARCHAR(50) = 'Open',
    @AssignedTo NVARCHAR(100) = NULL,
    @ContractorId INT = NULL,
    @NewMaintenanceId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pm.MAINTENANCE (
        property_id, contractor_id, description,
        action_plan, status, assigned_to
    )
    VALUES (
        @PropertyId, @ContractorId, @Description,
        @ActionPlan, @Status, @AssignedTo
    );

    SET @NewMaintenanceId = SCOPE_IDENTITY();

    EXEC pm.sp_GetMaintenanceById @NewMaintenanceId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateMaintenance
    @MaintenanceId INT,
    @Description NVARCHAR(255) = NULL,
    @ActionPlan NVARCHAR(255) = NULL,
    @Status NVARCHAR(50) = NULL,
    @AssignedTo NVARCHAR(100) = NULL,
    @ContractorId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.MAINTENANCE
    SET
        description = COALESCE(@Description, description),
        action_plan = COALESCE(@ActionPlan, action_plan),
        status = COALESCE(@Status, status),
        assigned_to = COALESCE(@AssignedTo, assigned_to),
        contractor_id = COALESCE(@ContractorId, contractor_id)
    WHERE maintenance_id = @MaintenanceId;

    EXEC pm.sp_GetMaintenanceById @MaintenanceId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_CloseMaintenance
    @MaintenanceId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.MAINTENANCE
    SET status = 'Closed'
    WHERE maintenance_id = @MaintenanceId;

    EXEC pm.sp_GetMaintenanceById @MaintenanceId;
END
GO

-- ==============================================================
-- 3. INSPECTIONS MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetInspections
    @PropertyId INT = NULL,
    @InspectionType NVARCHAR(100) = NULL,
    @NeedInspection NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.inspection_id,
        i.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        it.inspection_type,
        i.last_inspection_date,
        i.need_inspection,
        i.inspection_notes,
        i.repairs_maintenance,
        i.follow_up_date
    FROM pm.INSPECTIONS i
    INNER JOIN pm.PROPERTIES p ON i.property_id = p.property_id
    INNER JOIN pm.INSPECTION_TYPE it ON i.inspection_type_id = it.inspection_type_id
    WHERE
        (@PropertyId IS NULL OR i.property_id = @PropertyId)
        AND (@InspectionType IS NULL OR it.inspection_type LIKE '%' + @InspectionType + '%')
        AND (@NeedInspection IS NULL OR i.need_inspection = @NeedInspection)
    ORDER BY i.last_inspection_date DESC;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetInspectionById
    @InspectionId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.inspection_id,
        i.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        it.inspection_type,
        i.last_inspection_date,
        i.need_inspection,
        i.inspection_notes,
        i.repairs_maintenance,
        i.follow_up_date
    FROM pm.INSPECTIONS i
    INNER JOIN pm.PROPERTIES p ON i.property_id = p.property_id
    INNER JOIN pm.INSPECTION_TYPE it ON i.inspection_type_id = it.inspection_type_id
    WHERE i.inspection_id = @InspectionId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_CreateInspection
    @PropertyId INT,
    @InspectionType NVARCHAR(100),
    @LastInspectionDate DATE = NULL,
    @NeedInspection NVARCHAR(50) = NULL,
    @InspectionNotes NVARCHAR(500) = NULL,
    @RepairsMaintenance NVARCHAR(255) = NULL,
    @FollowUpDate DATE = NULL,
    @NewInspectionId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InspectionTypeId INT;

    -- Get or create inspection type
    SELECT @InspectionTypeId = inspection_type_id
    FROM pm.INSPECTION_TYPE
    WHERE inspection_type = @InspectionType;

    IF @InspectionTypeId IS NULL
    BEGIN
        INSERT INTO pm.INSPECTION_TYPE (inspection_type)
        VALUES (@InspectionType);
        SET @InspectionTypeId = SCOPE_IDENTITY();
    END

    INSERT INTO pm.INSPECTIONS (
        property_id, inspection_type_id, last_inspection_date,
        need_inspection, inspection_notes, repairs_maintenance, follow_up_date
    )
    VALUES (
        @PropertyId, @InspectionTypeId, @LastInspectionDate,
        @NeedInspection, @InspectionNotes, @RepairsMaintenance, @FollowUpDate
    );

    SET @NewInspectionId = SCOPE_IDENTITY();

    EXEC pm.sp_GetInspectionById @NewInspectionId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateInspection
    @InspectionId INT,
    @LastInspectionDate DATE = NULL,
    @NeedInspection NVARCHAR(50) = NULL,
    @InspectionNotes NVARCHAR(500) = NULL,
    @RepairsMaintenance NVARCHAR(255) = NULL,
    @FollowUpDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.INSPECTIONS
    SET
        last_inspection_date = COALESCE(@LastInspectionDate, last_inspection_date),
        need_inspection = COALESCE(@NeedInspection, need_inspection),
        inspection_notes = COALESCE(@InspectionNotes, inspection_notes),
        repairs_maintenance = COALESCE(@RepairsMaintenance, repairs_maintenance),
        follow_up_date = COALESCE(@FollowUpDate, follow_up_date)
    WHERE inspection_id = @InspectionId;

    EXEC pm.sp_GetInspectionById @InspectionId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetInspectionsDue
    @DaysOverdue INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.inspection_id,
        i.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        it.inspection_type,
        i.last_inspection_date,
        DATEDIFF(day, i.last_inspection_date, GETDATE()) AS days_since_last,
        i.follow_up_date,
        i.need_inspection
    FROM pm.INSPECTIONS i
    INNER JOIN pm.PROPERTIES p ON i.property_id = p.property_id
    INNER JOIN pm.INSPECTION_TYPE it ON i.inspection_type_id = it.inspection_type_id
    WHERE
        i.need_inspection = 'Yes'
        OR (i.follow_up_date IS NOT NULL AND i.follow_up_date <= DATEADD(day, @DaysOverdue, GETDATE()))
    ORDER BY i.follow_up_date ASC, i.last_inspection_date ASC;
END
GO

-- ==============================================================
-- 4. INSPECTION ISSUES MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetInspectionIssues
    @InspectionId INT = NULL,
    @Status NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ii.issue_id,
        ii.inspection_id,
        i.property_id,
        p.building_no,
        p.unit_number,
        ii.description_of_issue,
        ii.action_plan,
        ii.checked_off_by,
        ii.status,
        ii.date_logged
    FROM pm.INSPECTION_ISSUES ii
    INNER JOIN pm.INSPECTIONS i ON ii.inspection_id = i.inspection_id
    INNER JOIN pm.PROPERTIES p ON i.property_id = p.property_id
    WHERE
        (@InspectionId IS NULL OR ii.inspection_id = @InspectionId)
        AND (@Status IS NULL OR ii.status = @Status)
    ORDER BY ii.date_logged DESC;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_CreateInspectionIssue
    @InspectionId INT,
    @DescriptionOfIssue NVARCHAR(500),
    @ActionPlan NVARCHAR(500) = NULL,
    @Status NVARCHAR(50) = 'Open',
    @NewIssueId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pm.INSPECTION_ISSUES (
        inspection_id, description_of_issue, action_plan, status
    )
    VALUES (
        @InspectionId, @DescriptionOfIssue, @ActionPlan, @Status
    );

    SET @NewIssueId = SCOPE_IDENTITY();

    SELECT * FROM pm.INSPECTION_ISSUES WHERE issue_id = @NewIssueId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateInspectionIssue
    @IssueId INT,
    @DescriptionOfIssue NVARCHAR(500) = NULL,
    @ActionPlan NVARCHAR(500) = NULL,
    @CheckedOffBy NVARCHAR(100) = NULL,
    @Status NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.INSPECTION_ISSUES
    SET
        description_of_issue = COALESCE(@DescriptionOfIssue, description_of_issue),
        action_plan = COALESCE(@ActionPlan, action_plan),
        checked_off_by = COALESCE(@CheckedOffBy, checked_off_by),
        status = COALESCE(@Status, status)
    WHERE issue_id = @IssueId;

    SELECT * FROM pm.INSPECTION_ISSUES WHERE issue_id = @IssueId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_CloseInspectionIssue
    @IssueId INT,
    @CheckedOffBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.INSPECTION_ISSUES
    SET
        status = 'Closed',
        checked_off_by = @CheckedOffBy
    WHERE issue_id = @IssueId;

    SELECT * FROM pm.INSPECTION_ISSUES WHERE issue_id = @IssueId;
END
GO
