-- ==============================================================
-- STORED PROCEDURES FOR UTILITIES, RENT, TAXES & ASSESSMENTS
-- ==============================================================

-- ==============================================================
-- 1. RENT MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetRentHistory
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.rent_id,
        r.property_id,
        p.building_no,
        p.unit_number,
        r.rent_year,
        r.rent_amount,
        r.effective_date,
        r.end_date,
        r.notes
    FROM pm.RENT r
    INNER JOIN pm.PROPERTIES p ON r.property_id = p.property_id
    WHERE r.property_id = @PropertyId
    ORDER BY r.effective_date DESC;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetCurrentRent
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        r.rent_id,
        r.property_id,
        p.building_no,
        p.unit_number,
        r.rent_year,
        r.rent_amount,
        r.effective_date,
        r.end_date,
        r.notes
    FROM pm.RENT r
    INNER JOIN pm.PROPERTIES p ON r.property_id = p.property_id
    WHERE
        r.property_id = @PropertyId
        AND r.effective_date <= GETDATE()
        AND (r.end_date IS NULL OR r.end_date >= GETDATE())
    ORDER BY r.effective_date DESC;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_AddRent
    @PropertyId INT,
    @RentYear INT,
    @RentAmount DECIMAL(10,2),
    @EffectiveDate DATE,
    @EndDate DATE = NULL,
    @Notes NVARCHAR(255) = NULL,
    @NewRentId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pm.RENT (
        property_id, rent_year, rent_amount,
        effective_date, end_date, notes
    )
    VALUES (
        @PropertyId, @RentYear, @RentAmount,
        @EffectiveDate, @EndDate, @Notes
    );

    SET @NewRentId = SCOPE_IDENTITY();

    SELECT * FROM pm.RENT WHERE rent_id = @NewRentId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateRent
    @RentId INT,
    @RentAmount DECIMAL(10,2) = NULL,
    @EndDate DATE = NULL,
    @Notes NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.RENT
    SET
        rent_amount = COALESCE(@RentAmount, rent_amount),
        end_date = COALESCE(@EndDate, end_date),
        notes = COALESCE(@Notes, notes)
    WHERE rent_id = @RentId;

    SELECT * FROM pm.RENT WHERE rent_id = @RentId;
END
GO

-- ==============================================================
-- 2. UTILITIES MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetUtilities
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.utility_id,
        u.property_id,
        p.building_no,
        p.unit_number,
        ut.utility_name AS utility_type,
        u.total_amount
    FROM pm.UTILITIES u
    INNER JOIN pm.PROPERTIES p ON u.property_id = p.property_id
    INNER JOIN pm.UTILITY_TYPE ut ON u.utype_id = ut.utype_id
    WHERE u.property_id = @PropertyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetUtilitySplit
    @UtilityId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        us.split_id,
        us.utility_id,
        up.payer AS payer_name,
        us.percentage,
        u.total_amount * (us.percentage / 100) AS calculated_amount
    FROM pm.UTILITY_SPLIT us
    INNER JOIN pm.UTILITY_PAYER up ON us.payer_id = up.payer_id
    INNER JOIN pm.UTILITIES u ON us.utility_id = u.utility_id
    WHERE us.utility_id = @UtilityId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_AddUtility
    @PropertyId INT,
    @UtilityType NVARCHAR(25),
    @TotalAmount DECIMAL(10,2),
    @NewUtilityId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UtypeId INT;

    -- Get or create utility type
    SELECT @UtypeId = utype_id FROM pm.UTILITY_TYPE WHERE utility_name = @UtilityType;

    IF @UtypeId IS NULL
    BEGIN
        INSERT INTO pm.UTILITY_TYPE (utility_name) VALUES (@UtilityType);
        SET @UtypeId = SCOPE_IDENTITY();
    END

    INSERT INTO pm.UTILITIES (property_id, utype_id, total_amount)
    VALUES (@PropertyId, @UtypeId, @TotalAmount);

    SET @NewUtilityId = SCOPE_IDENTITY();

    SELECT
        u.utility_id,
        u.property_id,
        ut.utility_name,
        u.total_amount
    FROM pm.UTILITIES u
    INNER JOIN pm.UTILITY_TYPE ut ON u.utype_id = ut.utype_id
    WHERE u.utility_id = @NewUtilityId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_AddUtilitySplit
    @UtilityId INT,
    @PayerName NVARCHAR(6),
    @Percentage DECIMAL(5,2),
    @NewSplitId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PayerId INT;

    -- Get or create payer
    SELECT @PayerId = payer_id FROM pm.UTILITY_PAYER WHERE payer = @PayerName;

    IF @PayerId IS NULL
    BEGIN
        INSERT INTO pm.UTILITY_PAYER (payer) VALUES (@PayerName);
        SET @PayerId = SCOPE_IDENTITY();
    END

    INSERT INTO pm.UTILITY_SPLIT (payer_id, utility_id, percentage)
    VALUES (@PayerId, @UtilityId, @Percentage);

    SET @NewSplitId = SCOPE_IDENTITY();

    EXEC pm.sp_GetUtilitySplit @UtilityId;
END
GO

-- ==============================================================
-- 3. TAXES MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetTaxes
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.tax_id,
        t.property_id,
        p.building_no,
        p.unit_number,
        t.municipal_eht,
        t.bc_speculation_tax,
        t.federal_uht
    FROM pm.TAXES t
    INNER JOIN pm.PROPERTIES p ON t.property_id = p.property_id
    WHERE t.property_id = @PropertyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateTaxes
    @PropertyId INT,
    @MunicipalEHT DECIMAL(10,2) = NULL,
    @BCSpeculationTax DECIMAL(10,2) = NULL,
    @FederalUHT DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if tax record exists
    IF EXISTS (SELECT 1 FROM pm.TAXES WHERE property_id = @PropertyId)
    BEGIN
        UPDATE pm.TAXES
        SET
            municipal_eht = COALESCE(@MunicipalEHT, municipal_eht),
            bc_speculation_tax = COALESCE(@BCSpeculationTax, bc_speculation_tax),
            federal_uht = COALESCE(@FederalUHT, federal_uht)
        WHERE property_id = @PropertyId;
    END
    ELSE
    BEGIN
        INSERT INTO pm.TAXES (property_id, municipal_eht, bc_speculation_tax, federal_uht)
        VALUES (@PropertyId, @MunicipalEHT, @BCSpeculationTax, @FederalUHT);
    END

    EXEC pm.sp_GetTaxes @PropertyId;
END
GO

-- ==============================================================
-- 4. BC ASSESSMENTS MANAGEMENT
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetAssessments
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.assessment_id,
        a.property_id,
        a.building_no,
        a.unit_number,
        a.[year],
        a.assessed_value
    FROM pm.BC_ASSESSMENTS a
    WHERE a.property_id = @PropertyId
    ORDER BY a.[year] DESC;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetAssessmentByYear
    @PropertyId INT,
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.assessment_id,
        a.property_id,
        a.building_no,
        a.unit_number,
        a.[year],
        a.assessed_value
    FROM pm.BC_ASSESSMENTS a
    WHERE a.property_id = @PropertyId AND a.[year] = @Year;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_AddAssessment
    @PropertyId INT,
    @Year INT,
    @AssessedValue DECIMAL(12,2),
    @NewAssessmentId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BuildingNo NVARCHAR(50), @UnitNumber NVARCHAR(50);

    -- Get building and unit from property
    SELECT @BuildingNo = building_no, @UnitNumber = unit_number
    FROM pm.PROPERTIES
    WHERE property_id = @PropertyId;

    INSERT INTO pm.BC_ASSESSMENTS (property_id, building_no, unit_number, [year], assessed_value)
    VALUES (@PropertyId, @BuildingNo, @UnitNumber, @Year, @AssessedValue);

    SET @NewAssessmentId = SCOPE_IDENTITY();

    SELECT * FROM pm.BC_ASSESSMENTS WHERE assessment_id = @NewAssessmentId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateAssessment
    @AssessmentId INT,
    @AssessedValue DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pm.BC_ASSESSMENTS
    SET assessed_value = @AssessedValue
    WHERE assessment_id = @AssessmentId;

    SELECT * FROM pm.BC_ASSESSMENTS WHERE assessment_id = @AssessmentId;
END
GO

-- ==============================================================
-- 5. BC SPECULATION TAX NOTICES
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetSpeculationNotices
    @PropertyId INT = NULL,
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sn.notice_id,
        sn.property_id,
        p.building_no,
        p.unit_number,
        sn.owner_first_name,
        sn.owner_last_name,
        sn.owner_email,
        sn.notice,
        sn.year_of_notice
    FROM pm.BC_SPECULATION_NOTICES sn
    INNER JOIN pm.PROPERTIES p ON sn.property_id = p.property_id
    WHERE
        (@PropertyId IS NULL OR sn.property_id = @PropertyId)
        AND (@Year IS NULL OR sn.year_of_notice = @Year)
    ORDER BY sn.year_of_notice DESC, sn.property_id;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_AddSpeculationNotice
    @PropertyId INT,
    @OwnerFirstName NVARCHAR(255),
    @OwnerLastName NVARCHAR(255),
    @OwnerEmail NVARCHAR(255),
    @Notice NVARCHAR(500) = NULL,
    @YearOfNotice INT,
    @NewNoticeId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pm.BC_SPECULATION_NOTICES (
        property_id, owner_first_name, owner_last_name,
        owner_email, notice, year_of_notice
    )
    VALUES (
        @PropertyId, @OwnerFirstName, @OwnerLastName,
        @OwnerEmail, @Notice, @YearOfNotice
    );

    SET @NewNoticeId = SCOPE_IDENTITY();

    SELECT * FROM pm.BC_SPECULATION_NOTICES WHERE notice_id = @NewNoticeId;
END
GO

-- ==============================================================
-- 6. BUILDING & STRATA MANAGERS
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetBuildingManager
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        bm.manager_id,
        bm.property_id,
        p.building_no,
        p.unit_number,
        bm.name,
        bm.phone,
        bm.email,
        bm.concierge_desk,
        bm.concierge_phone,
        bm.concierge_email
    FROM pm.BUILDING_MANAGERS bm
    INNER JOIN pm.PROPERTIES p ON bm.property_id = p.property_id
    WHERE bm.property_id = @PropertyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateBuildingManager
    @PropertyId INT,
    @Name NVARCHAR(100) = NULL,
    @Phone NVARCHAR(50) = NULL,
    @Email NVARCHAR(255) = NULL,
    @ConciergeDesk NVARCHAR(100) = NULL,
    @ConciergePhone NVARCHAR(50) = NULL,
    @ConciergeEmail NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM pm.BUILDING_MANAGERS WHERE property_id = @PropertyId)
    BEGIN
        UPDATE pm.BUILDING_MANAGERS
        SET
            name = COALESCE(@Name, name),
            phone = COALESCE(@Phone, phone),
            email = COALESCE(@Email, email),
            concierge_desk = COALESCE(@ConciergeDesk, concierge_desk),
            concierge_phone = COALESCE(@ConciergePhone, concierge_phone),
            concierge_email = COALESCE(@ConciergeEmail, concierge_email)
        WHERE property_id = @PropertyId;
    END
    ELSE
    BEGIN
        INSERT INTO pm.BUILDING_MANAGERS (
            property_id, name, phone, email,
            concierge_desk, concierge_phone, concierge_email
        )
        VALUES (
            @PropertyId, @Name, @Phone, @Email,
            @ConciergeDesk, @ConciergePhone, @ConciergeEmail
        );
    END

    EXEC pm.sp_GetBuildingManager @PropertyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetStrataManager
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sm.strata_id,
        sm.property_id,
        p.building_no,
        p.unit_number,
        sm.strata_number,
        sm.strata_lot,
        sm.manager_name,
        sm.contact_number,
        sm.email
    FROM pm.STRATA_MANAGERS sm
    INNER JOIN pm.PROPERTIES p ON sm.property_id = p.property_id
    WHERE sm.property_id = @PropertyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdateStrataManager
    @PropertyId INT,
    @StrataNumber NVARCHAR(50) = NULL,
    @StrataLot NVARCHAR(50) = NULL,
    @ManagerName NVARCHAR(100) = NULL,
    @ContactNumber NVARCHAR(50) = NULL,
    @Email NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM pm.STRATA_MANAGERS WHERE property_id = @PropertyId)
    BEGIN
        UPDATE pm.STRATA_MANAGERS
        SET
            strata_number = COALESCE(@StrataNumber, strata_number),
            strata_lot = COALESCE(@StrataLot, strata_lot),
            manager_name = COALESCE(@ManagerName, manager_name),
            contact_number = COALESCE(@ContactNumber, contact_number),
            email = COALESCE(@Email, email)
        WHERE property_id = @PropertyId;
    END
    ELSE
    BEGIN
        INSERT INTO pm.STRATA_MANAGERS (
            property_id, strata_number, strata_lot,
            manager_name, contact_number, email
        )
        VALUES (
            @PropertyId, @StrataNumber, @StrataLot,
            @ManagerName, @ContactNumber, @Email
        );
    END

    EXEC pm.sp_GetStrataManager @PropertyId;
END
GO
