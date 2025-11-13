-- ==============================================================
-- STORED PROCEDURES FOR OWNERS & OWNERSHIP MANAGEMENT
-- ==============================================================

-- ==============================================================
-- 1. SEARCH/GET OWNERS
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetAllOwners
    @FirstName NVARCHAR(100) = NULL,
    @LastName NVARCHAR(100) = NULL,
    @CompanyName NVARCHAR(100) = NULL,
    @Email NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.owner_id,
        o.first_name,
        o.last_name,
        o.company_name,
        o.type_of_owner,
        o.phone_number,
        o.email,
        c.first_name AS care_of_first_name,
        c.last_name AS care_of_last_name,
        c.phone_number AS care_of_phone,
        c.email AS care_of_email
    FROM pm.OWNERS o
    LEFT JOIN pm.CARE_OF c ON o.care_of = c.care_of_id
    WHERE
        (@FirstName IS NULL OR o.first_name LIKE '%' + @FirstName + '%')
        AND (@LastName IS NULL OR o.last_name LIKE '%' + @LastName + '%')
        AND (@CompanyName IS NULL OR o.company_name LIKE '%' + @CompanyName + '%')
        AND (@Email IS NULL OR o.email LIKE '%' + @Email + '%')
    ORDER BY o.last_name, o.first_name;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetOwnerById
    @OwnerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.owner_id,
        o.first_name,
        o.last_name,
        o.company_name,
        o.type_of_owner,
        o.phone_number,
        o.email,
        c.care_of_id,
        c.first_name AS care_of_first_name,
        c.last_name AS care_of_last_name,
        c.phone_number AS care_of_phone,
        c.email AS care_of_email
    FROM pm.OWNERS o
    LEFT JOIN pm.CARE_OF c ON o.care_of = c.care_of_id
    WHERE o.owner_id = @OwnerId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetOwnersByProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.owner_id,
        o.first_name,
        o.last_name,
        o.company_name,
        o.type_of_owner,
        o.phone_number,
        o.email,
        p.building_no,
        p.unit_number,
        p.address
    FROM pm.OWNERSHIP ow
    INNER JOIN pm.OWNERS o ON ow.frn_owner_id = o.owner_id
    INNER JOIN pm.PROPERTIES p ON ow.frn_property_id = p.property_id
    WHERE ow.frn_property_id = @PropertyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetPropertiesByOwner
    @OwnerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        c.city,
        pr.province,
        pt.unit_type,
        p.status
    FROM pm.OWNERSHIP ow
    INNER JOIN pm.PROPERTIES p ON ow.frn_property_id = p.property_id
    LEFT JOIN pm.CITY c ON p.city_id = c.city_id
    LEFT JOIN pm.PROVINCE pr ON p.province_id = pr.province_id
    LEFT JOIN pm.PROPERTY_TYPE pt ON p.unit_type_id = pt.unit_type_id
    WHERE ow.frn_owner_id = @OwnerId;
END
GO

-- ==============================================================
-- 2. CREATE OWNER
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_CreateOwner
    @FirstName NVARCHAR(100) = NULL,
    @LastName NVARCHAR(100) = NULL,
    @CompanyName NVARCHAR(100) = NULL,
    @TypeOfOwner NVARCHAR(50) = NULL,
    @PhoneNumber NVARCHAR(50) = NULL,
    @Email NVARCHAR(255) = NULL,
    @CareOfFirstName NVARCHAR(100) = NULL,
    @CareOfLastName NVARCHAR(100) = NULL,
    @CareOfPhone NVARCHAR(50) = NULL,
    @CareOfEmail NVARCHAR(255) = NULL,
    @NewOwnerId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CareOfId INT = NULL;

    -- Create Care Of contact if provided
    IF @CareOfFirstName IS NOT NULL OR @CareOfLastName IS NOT NULL
    BEGIN
        INSERT INTO pm.CARE_OF (first_name, last_name, phone_number, email)
        VALUES (@CareOfFirstName, @CareOfLastName, @CareOfPhone, @CareOfEmail);
        SET @CareOfId = SCOPE_IDENTITY();
    END

    -- Create Owner
    INSERT INTO pm.OWNERS (
        first_name, last_name, company_name, type_of_owner,
        phone_number, email, care_of
    )
    VALUES (
        @FirstName, @LastName, @CompanyName, @TypeOfOwner,
        @PhoneNumber, @Email, @CareOfId
    );

    SET @NewOwnerId = SCOPE_IDENTITY();

    EXEC pm.sp_GetOwnerById @NewOwnerId;
END
GO

-- ==============================================================
-- 3. UPDATE OWNER
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_UpdateOwner
    @OwnerId INT,
    @FirstName NVARCHAR(100) = NULL,
    @LastName NVARCHAR(100) = NULL,
    @CompanyName NVARCHAR(100) = NULL,
    @TypeOfOwner NVARCHAR(50) = NULL,
    @PhoneNumber NVARCHAR(50) = NULL,
    @Email NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.OWNERS
    SET
        first_name = COALESCE(@FirstName, first_name),
        last_name = COALESCE(@LastName, last_name),
        company_name = COALESCE(@CompanyName, company_name),
        type_of_owner = COALESCE(@TypeOfOwner, type_of_owner),
        phone_number = COALESCE(@PhoneNumber, phone_number),
        email = COALESCE(@Email, email)
    WHERE owner_id = @OwnerId;

    EXEC pm.sp_GetOwnerById @OwnerId;
END
GO

-- ==============================================================
-- 4. ASSIGN PROPERTY TO OWNER (CREATE OWNERSHIP)
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_AssignPropertyToOwner
    @OwnerId INT,
    @PropertyId INT,
    @NewOwnershipId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if ownership already exists
    IF EXISTS (SELECT 1 FROM pm.OWNERSHIP WHERE frn_owner_id = @OwnerId AND frn_property_id = @PropertyId)
    BEGIN
        SELECT 'Ownership already exists' AS Message;
        RETURN;
    END

    INSERT INTO pm.OWNERSHIP (frn_owner_id, frn_property_id)
    VALUES (@OwnerId, @PropertyId);

    SET @NewOwnershipId = SCOPE_IDENTITY();

    SELECT
        ownership_id,
        frn_owner_id AS owner_id,
        frn_property_id AS property_id
    FROM pm.OWNERSHIP
    WHERE ownership_id = @NewOwnershipId;
END
GO

-- ==============================================================
-- 5. REMOVE PROPERTY FROM OWNER
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_RemovePropertyFromOwner
    @OwnerId INT,
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM pm.OWNERSHIP
    WHERE frn_owner_id = @OwnerId AND frn_property_id = @PropertyId;

    SELECT 'Ownership removed successfully' AS Message;
END
GO

-- ==============================================================
-- 6. OWNER INSURANCE MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetOwnerInsurance
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        oi.owner_insurance_id,
        oi.property_id,
        p.building_no,
        p.unit_number,
        oi.policy_number,
        oi.insurance_start_date,
        oi.insurance_end_date,
        oi.remarks
    FROM pm.OWNER_INSURANCE oi
    INNER JOIN pm.PROPERTIES p ON oi.property_id = p.property_id
    WHERE oi.property_id = @PropertyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_AddOwnerInsurance
    @PropertyId INT,
    @PolicyNumber NVARCHAR(100),
    @InsuranceStartDate DATE = NULL,
    @InsuranceEndDate DATE = NULL,
    @Remarks NVARCHAR(255) = NULL,
    @NewInsuranceId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pm.OWNER_INSURANCE (
        property_id, policy_number, insurance_start_date,
        insurance_end_date, remarks
    )
    VALUES (
        @PropertyId, @PolicyNumber, @InsuranceStartDate,
        @InsuranceEndDate, @Remarks
    );

    SET @NewInsuranceId = SCOPE_IDENTITY();

    SELECT * FROM pm.OWNER_INSURANCE WHERE owner_insurance_id = @NewInsuranceId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateOwnerInsurance
    @InsuranceId INT,
    @PolicyNumber NVARCHAR(100) = NULL,
    @InsuranceStartDate DATE = NULL,
    @InsuranceEndDate DATE = NULL,
    @Remarks NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.OWNER_INSURANCE
    SET
        policy_number = COALESCE(@PolicyNumber, policy_number),
        insurance_start_date = COALESCE(@InsuranceStartDate, insurance_start_date),
        insurance_end_date = COALESCE(@InsuranceEndDate, insurance_end_date),
        remarks = COALESCE(@Remarks, remarks)
    WHERE owner_insurance_id = @InsuranceId;

    SELECT * FROM pm.OWNER_INSURANCE WHERE owner_insurance_id = @InsuranceId;
END
GO

-- ==============================================================
-- 7. GET EXPIRING OWNER INSURANCES
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetExpiringOwnerInsurances
    @DaysAhead INT = 60
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        oi.owner_insurance_id,
        oi.property_id,
        p.building_no,
        p.unit_number,
        oi.policy_number,
        oi.insurance_end_date,
        DATEDIFF(day, GETDATE(), oi.insurance_end_date) AS days_until_expiry,
        o.first_name AS owner_first_name,
        o.last_name AS owner_last_name,
        o.email AS owner_email
    FROM pm.OWNER_INSURANCE oi
    INNER JOIN pm.PROPERTIES p ON oi.property_id = p.property_id
    LEFT JOIN pm.OWNERSHIP ow ON p.property_id = ow.frn_property_id
    LEFT JOIN pm.OWNERS o ON ow.frn_owner_id = o.owner_id
    WHERE
        oi.insurance_end_date IS NOT NULL
        AND oi.insurance_end_date BETWEEN GETDATE() AND DATEADD(day, @DaysAhead, GETDATE())
    ORDER BY oi.insurance_end_date ASC;
END
GO
