-- ==============================================================
-- STORED PROCEDURES FOR TENANTS & TENANCY MANAGEMENT
-- ==============================================================

-- ==============================================================
-- 1. SEARCH/GET TENANCIES
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetActiveTenancies
    @PropertyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.tenancy_id,
        t.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        t.lease_start_date,
        t.lease_end_date,
        t.lease_status,
        t.term,
        t.security_deposit,
        t.security_deposit_date,
        t.pet_deposit,
        t.pet_deposit_date,
        t.last_rent_increase,
        ti.policy_number AS insurance_policy,
        ti.insurance_start_date,
        ti.insurance_end_date
    FROM pm.TENANCY t
    INNER JOIN pm.PROPERTIES p ON t.property_id = p.property_id
    LEFT JOIN pm.TENANT_INSURANCE ti ON t.insurance_id = ti.insurance_id
    WHERE
        (@PropertyId IS NULL OR t.property_id = @PropertyId)
        AND (t.lease_status = 'Active' OR t.lease_end_date >= GETDATE())
    ORDER BY t.lease_start_date DESC;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetTenancyById
    @TenancyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.tenancy_id,
        t.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        t.lease_start_date,
        t.lease_end_date,
        t.lease_status,
        t.term,
        t.security_deposit,
        t.security_deposit_date,
        t.pet_deposit,
        t.pet_deposit_date,
        t.last_rent_increase,
        ti.policy_number AS insurance_policy,
        ti.insurance_start_date,
        ti.insurance_end_date
    FROM pm.TENANCY t
    INNER JOIN pm.PROPERTIES p ON t.property_id = p.property_id
    LEFT JOIN pm.TENANT_INSURANCE ti ON t.insurance_id = ti.insurance_id
    WHERE t.tenancy_id = @TenancyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetExpiringLeases
    @DaysAhead INT = 90
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.tenancy_id,
        t.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        t.lease_start_date,
        t.lease_end_date,
        DATEDIFF(day, GETDATE(), t.lease_end_date) AS days_until_expiry,
        t.lease_status,
        t.term
    FROM pm.TENANCY t
    INNER JOIN pm.PROPERTIES p ON t.property_id = p.property_id
    WHERE
        t.lease_end_date IS NOT NULL
        AND t.lease_end_date BETWEEN GETDATE() AND DATEADD(day, @DaysAhead, GETDATE())
    ORDER BY t.lease_end_date ASC;
END
GO

-- ==============================================================
-- 2. GET TENANTS
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetTenantsByTenancy
    @TenancyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.tenant_id,
        t.tenancy_id,
        t.first_name,
        t.last_name,
        t.email,
        t.phone_number AS mobile
    FROM pm.TENANT t
    WHERE t.tenancy_id = @TenancyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_SearchTenants
    @FirstName NVARCHAR(100) = NULL,
    @LastName NVARCHAR(100) = NULL,
    @Email NVARCHAR(150) = NULL,
    @PhoneNumber NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.tenant_id,
        t.tenancy_id,
        t.first_name,
        t.last_name,
        t.email,
        t.phone_number AS mobile,
        tn.property_id,
        p.building_no,
        p.unit_number,
        tn.lease_status
    FROM pm.TENANT t
    INNER JOIN pm.TENANCY tn ON t.tenancy_id = tn.tenancy_id
    INNER JOIN pm.PROPERTIES p ON tn.property_id = p.property_id
    WHERE
        (@FirstName IS NULL OR t.first_name LIKE '%' + @FirstName + '%')
        AND (@LastName IS NULL OR t.last_name LIKE '%' + @LastName + '%')
        AND (@Email IS NULL OR t.email LIKE '%' + @Email + '%')
        AND (@PhoneNumber IS NULL OR t.phone_number LIKE '%' + @PhoneNumber + '%');
END
GO

-- ==============================================================
-- 3. CREATE TENANCY
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_CreateTenancy
    @PropertyId INT,
    @LeaseStartDate DATE,
    @LeaseEndDate DATE = NULL,
    @LeaseStatus NVARCHAR(50) = 'Active',
    @Term NVARCHAR(50) = NULL,
    @SecurityDeposit DECIMAL(10,2) = NULL,
    @SecurityDepositDate DATE = NULL,
    @PetDeposit DECIMAL(10,2) = NULL,
    @PetDepositDate DATE = NULL,
    @LastRentIncrease DATE = NULL,
    @InsurancePolicyNumber NVARCHAR(100) = NULL,
    @InsuranceStartDate DATE = NULL,
    @InsuranceEndDate DATE = NULL,
    @NewTenancyId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InsuranceId INT = NULL;

    -- Create insurance if provided
    IF @InsurancePolicyNumber IS NOT NULL
    BEGIN
        INSERT INTO pm.TENANT_INSURANCE (policy_number, insurance_start_date, insurance_end_date)
        VALUES (@InsurancePolicyNumber, @InsuranceStartDate, @InsuranceEndDate);
        SET @InsuranceId = SCOPE_IDENTITY();
    END

    -- Create tenancy
    INSERT INTO pm.TENANCY (
        property_id, insurance_id, lease_start_date, lease_end_date,
        lease_status, term, security_deposit, security_deposit_date,
        pet_deposit, pet_deposit_date, last_rent_increase
    )
    VALUES (
        @PropertyId, @InsuranceId, @LeaseStartDate, @LeaseEndDate,
        @LeaseStatus, @Term, @SecurityDeposit, @SecurityDepositDate,
        @PetDeposit, @PetDepositDate, @LastRentIncrease
    );

    SET @NewTenancyId = SCOPE_IDENTITY();

    -- Return created tenancy
    EXEC pm.sp_GetTenancyById @NewTenancyId;
END
GO

-- ==============================================================
-- 4. ADD TENANT TO TENANCY
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_AddTenant
    @TenancyId INT,
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @Email NVARCHAR(150) = NULL,
    @Mobile NVARCHAR(20) = NULL,
    @NewTenantId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pm.TENANT (tenancy_id, first_name, last_name, email, phone_number)
    VALUES (@TenancyId, @FirstName, @LastName, @Email, @Mobile);

    SET @NewTenantId = SCOPE_IDENTITY();

    SELECT
        tenant_id,
        tenancy_id,
        first_name,
        last_name,
        email,
        phone_number AS mobile
    FROM pm.TENANT
    WHERE tenant_id = @NewTenantId;
END
GO

-- ==============================================================
-- 5. UPDATE TENANCY
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_UpdateTenancy
    @TenancyId INT,
    @LeaseEndDate DATE = NULL,
    @LeaseStatus NVARCHAR(50) = NULL,
    @Term NVARCHAR(50) = NULL,
    @SecurityDeposit DECIMAL(10,2) = NULL,
    @SecurityDepositDate DATE = NULL,
    @PetDeposit DECIMAL(10,2) = NULL,
    @PetDepositDate DATE = NULL,
    @LastRentIncrease DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.TENANCY
    SET
        lease_end_date = COALESCE(@LeaseEndDate, lease_end_date),
        lease_status = COALESCE(@LeaseStatus, lease_status),
        term = COALESCE(@Term, term),
        security_deposit = COALESCE(@SecurityDeposit, security_deposit),
        security_deposit_date = COALESCE(@SecurityDepositDate, security_deposit_date),
        pet_deposit = COALESCE(@PetDeposit, pet_deposit),
        pet_deposit_date = COALESCE(@PetDepositDate, pet_deposit_date),
        last_rent_increase = COALESCE(@LastRentIncrease, last_rent_increase)
    WHERE tenancy_id = @TenancyId;

    EXEC pm.sp_GetTenancyById @TenancyId;
END
GO

-- ==============================================================
-- 6. UPDATE TENANT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_UpdateTenant
    @TenantId INT,
    @FirstName NVARCHAR(100) = NULL,
    @LastName NVARCHAR(100) = NULL,
    @Email NVARCHAR(150) = NULL,
    @Mobile NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.TENANT
    SET
        first_name = COALESCE(@FirstName, first_name),
        last_name = COALESCE(@LastName, last_name),
        email = COALESCE(@Email, email),
        phone_number = COALESCE(@Mobile, phone_number)
    WHERE tenant_id = @TenantId;

    SELECT
        tenant_id,
        tenancy_id,
        first_name,
        last_name,
        email,
        phone_number AS mobile
    FROM pm.TENANT
    WHERE tenant_id = @TenantId;
END
GO

-- ==============================================================
-- 7. UPDATE TENANT INSURANCE
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_UpdateTenantInsurance
    @TenancyId INT,
    @PolicyNumber NVARCHAR(100),
    @InsuranceStartDate DATE = NULL,
    @InsuranceEndDate DATE = NULL,
    @Remarks NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InsuranceId INT;

    -- Get current insurance ID
    SELECT @InsuranceId = insurance_id FROM pm.TENANCY WHERE tenancy_id = @TenancyId;

    IF @InsuranceId IS NOT NULL
    BEGIN
        -- Update existing
        UPDATE pm.TENANT_INSURANCE
        SET
            policy_number = COALESCE(@PolicyNumber, policy_number),
            insurance_start_date = COALESCE(@InsuranceStartDate, insurance_start_date),
            insurance_end_date = COALESCE(@InsuranceEndDate, insurance_end_date),
            remarks = COALESCE(@Remarks, remarks)
        WHERE insurance_id = @InsuranceId;
    END
    ELSE
    BEGIN
        -- Create new insurance
        INSERT INTO pm.TENANT_INSURANCE (policy_number, insurance_start_date, insurance_end_date, remarks)
        VALUES (@PolicyNumber, @InsuranceStartDate, @InsuranceEndDate, @Remarks);

        SET @InsuranceId = SCOPE_IDENTITY();

        -- Link to tenancy
        UPDATE pm.TENANCY
        SET insurance_id = @InsuranceId
        WHERE tenancy_id = @TenancyId;
    END

    EXEC pm.sp_GetTenancyById @TenancyId;
END
GO

-- ==============================================================
-- 8. MOVE IN/OUT MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_CreateMove
    @TenancyId INT,
    @MoveType NVARCHAR(20), -- 'Move In' or 'Move Out'
    @MoveDate DATE = NULL,
    @TenantAvailability NVARCHAR(50) = NULL,
    @ProposedDateTBC BIT = 0,
    @ConfirmedWithDavid BIT = 0,
    @Status NVARCHAR(50) = 'Pending',
    @NotifyBackOffice BIT = 0,
    @SecurityRelease BIT = 0,
    @MoveOutLetter BIT = 0,
    @MoveInOrientation BIT = 0,
    @FormK BIT = 0,
    @Zinspector NVARCHAR(100) = NULL,
    @NewMoveId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MoveTypeId INT;

    -- Get or create move type
    SELECT @MoveTypeId = move_type_id FROM pm.MOVE_TYPE WHERE move_type_id =
        CASE WHEN @MoveType = 'Move In' THEN 1 ELSE 2 END;

    -- For simplicity, using 1 = Move In, 2 = Move Out
    IF @MoveTypeId IS NULL
        SET @MoveTypeId = CASE WHEN @MoveType = 'Move In' THEN 1 ELSE 2 END;

    INSERT INTO pm.MOVE (
        move_type_id, tenancy_id, move_date, tenant_availability,
        proposed_date_tbc, confirmed_with_david, status,
        notify_back_office, security_release, move_out_letter,
        move_in_orientation, form_k, zinspector
    )
    VALUES (
        @MoveTypeId, @TenancyId, @MoveDate, @TenantAvailability,
        @ProposedDateTBC, @ConfirmedWithDavid, @Status,
        @NotifyBackOffice, @SecurityRelease, @MoveOutLetter,
        @MoveInOrientation, @FormK, @Zinspector
    );

    SET @NewMoveId = SCOPE_IDENTITY();

    SELECT * FROM pm.MOVE WHERE move_id = @NewMoveId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetUpcomingMoves
    @DaysAhead INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.move_id,
        m.move_type_id,
        m.tenancy_id,
        m.move_date,
        DATEDIFF(day, GETDATE(), m.move_date) AS days_until_move,
        m.status,
        p.building_no,
        p.unit_number,
        p.address
    FROM pm.MOVE m
    INNER JOIN pm.TENANCY t ON m.tenancy_id = t.tenancy_id
    INNER JOIN pm.PROPERTIES p ON t.property_id = p.property_id
    WHERE
        m.move_date BETWEEN GETDATE() AND DATEADD(day, @DaysAhead, GETDATE())
    ORDER BY m.move_date ASC;
END
GO
