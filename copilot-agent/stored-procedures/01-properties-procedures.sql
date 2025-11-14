-- ==============================================================
-- STORED PROCEDURES FOR PROPERTIES MANAGEMENT
-- ==============================================================

-- ==============================================================
-- 1. SEARCH/GET PROPERTIES
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetAllProperties
    @CityName NVARCHAR(100) = NULL,
    @ProvinceName NVARCHAR(100) = NULL,
    @Status NVARCHAR(50) = NULL,
    @UnitType NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        p.postal_code,
        c.city,
        pr.province,
        pt.unit_type,
        p.management_start_date,
        p.length_of_service,
        p.status,
        p.storage_locker,
        p.parking_stall,
        p.remarks
    FROM pm.PROPERTIES p
    LEFT JOIN pm.CITY c ON p.city_id = c.city_id
    LEFT JOIN pm.PROVINCE pr ON p.province_id = pr.province_id
    LEFT JOIN pm.PROPERTY_TYPE pt ON p.unit_type_id = pt.unit_type_id
    WHERE
        (@CityName IS NULL OR c.city LIKE '%' + @CityName + '%')
        AND (@ProvinceName IS NULL OR pr.province LIKE '%' + @ProvinceName + '%')
        AND (@Status IS NULL OR p.status = @Status)
        AND (@UnitType IS NULL OR pt.unit_type LIKE '%' + @UnitType + '%')
    ORDER BY p.building_no, p.unit_number;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_GetPropertyById
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        p.postal_code,
        c.city,
        pr.province,
        pt.unit_type,
        p.management_start_date,
        p.length_of_service,
        p.status,
        p.storage_locker,
        p.parking_stall,
        p.remarks
    FROM pm.PROPERTIES p
    LEFT JOIN pm.CITY c ON p.city_id = c.city_id
    LEFT JOIN pm.PROVINCE pr ON p.province_id = pr.province_id
    LEFT JOIN pm.PROPERTY_TYPE pt ON p.unit_type_id = pt.unit_type_id
    WHERE p.property_id = @PropertyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_FindPropertyByAddress
    @BuildingNo NVARCHAR(50),
    @UnitNumber NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.property_id,
        p.building_no,
        p.unit_number,
        p.address,
        p.postal_code,
        c.city,
        pr.province,
        pt.unit_type,
        p.management_start_date,
        p.length_of_service,
        p.status,
        p.storage_locker,
        p.parking_stall,
        p.remarks
    FROM pm.PROPERTIES p
    LEFT JOIN pm.CITY c ON p.city_id = c.city_id
    LEFT JOIN pm.PROVINCE pr ON p.province_id = pr.province_id
    LEFT JOIN pm.PROPERTY_TYPE pt ON p.unit_type_id = pt.unit_type_id
    WHERE p.building_no = @BuildingNo AND p.unit_number = @UnitNumber;
END
GO

-- ==============================================================
-- 2. CREATE PROPERTY
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_CreateProperty
    @BuildingNo NVARCHAR(50),
    @UnitNumber NVARCHAR(50),
    @Address NVARCHAR(255) = NULL,
    @PostalCode NVARCHAR(20) = NULL,
    @CityName NVARCHAR(100) = NULL,
    @ProvinceName NVARCHAR(100) = NULL,
    @UnitType NVARCHAR(100) = NULL,
    @ManagementStartDate DATE = NULL,
    @LengthOfService NVARCHAR(50) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StorageLocker NVARCHAR(100) = NULL,
    @ParkingStall NVARCHAR(50) = NULL,
    @Remarks NVARCHAR(500) = NULL,
    @NewPropertyId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CityId INT, @ProvinceId INT, @UnitTypeId INT;

    -- Get or create City
    IF @CityName IS NOT NULL
    BEGIN
        SELECT @CityId = city_id FROM pm.CITY WHERE city = @CityName;
        IF @CityId IS NULL
        BEGIN
            INSERT INTO pm.CITY (city) VALUES (@CityName);
            SET @CityId = SCOPE_IDENTITY();
        END
    END

    -- Get or create Province
    IF @ProvinceName IS NOT NULL
    BEGIN
        SELECT @ProvinceId = province_id FROM pm.PROVINCE WHERE province = @ProvinceName;
        IF @ProvinceId IS NULL
        BEGIN
            INSERT INTO pm.PROVINCE (province) VALUES (@ProvinceName);
            SET @ProvinceId = SCOPE_IDENTITY();
        END
    END

    -- Get or create Unit Type
    IF @UnitType IS NOT NULL
    BEGIN
        SELECT @UnitTypeId = unit_type_id FROM pm.PROPERTY_TYPE WHERE unit_type = @UnitType;
        IF @UnitTypeId IS NULL
        BEGIN
            INSERT INTO pm.PROPERTY_TYPE (unit_type) VALUES (@UnitType);
            SET @UnitTypeId = SCOPE_IDENTITY();
        END
    END

    -- Insert Property
    INSERT INTO pm.PROPERTIES (
        building_no, unit_number, address, postal_code,
        city_id, province_id, unit_type_id,
        management_start_date, length_of_service, status,
        storage_locker, parking_stall, remarks
    )
    VALUES (
        @BuildingNo, @UnitNumber, @Address, @PostalCode,
        @CityId, @ProvinceId, @UnitTypeId,
        @ManagementStartDate, @LengthOfService, @Status,
        @StorageLocker, @ParkingStall, @Remarks
    );

    SET @NewPropertyId = SCOPE_IDENTITY();

    -- Return the created property
    EXEC pm.sp_GetPropertyById @NewPropertyId;
END
GO

-- ==============================================================
-- 3. UPDATE PROPERTY
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_UpdateProperty
    @PropertyId INT,
    @Address NVARCHAR(255) = NULL,
    @PostalCode NVARCHAR(20) = NULL,
    @CityName NVARCHAR(100) = NULL,
    @ProvinceName NVARCHAR(100) = NULL,
    @UnitType NVARCHAR(100) = NULL,
    @ManagementStartDate DATE = NULL,
    @LengthOfService NVARCHAR(50) = NULL,
    @Status NVARCHAR(50) = NULL,
    @StorageLocker NVARCHAR(100) = NULL,
    @ParkingStall NVARCHAR(50) = NULL,
    @Remarks NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CityId INT, @ProvinceId INT, @UnitTypeId INT;

    -- Get or create City
    IF @CityName IS NOT NULL
    BEGIN
        SELECT @CityId = city_id FROM pm.CITY WHERE city = @CityName;
        IF @CityId IS NULL
        BEGIN
            INSERT INTO pm.CITY (city) VALUES (@CityName);
            SET @CityId = SCOPE_IDENTITY();
        END
    END

    -- Get or create Province
    IF @ProvinceName IS NOT NULL
    BEGIN
        SELECT @ProvinceId = province_id FROM pm.PROVINCE WHERE province = @ProvinceName;
        IF @ProvinceId IS NULL
        BEGIN
            INSERT INTO pm.PROVINCE (province) VALUES (@ProvinceName);
            SET @ProvinceId = SCOPE_IDENTITY();
        END
    END

    -- Get or create Unit Type
    IF @UnitType IS NOT NULL
    BEGIN
        SELECT @UnitTypeId = unit_type_id FROM pm.PROPERTY_TYPE WHERE unit_type = @UnitType;
        IF @UnitTypeId IS NULL
        BEGIN
            INSERT INTO pm.PROPERTY_TYPE (unit_type) VALUES (@UnitType);
            SET @UnitTypeId = SCOPE_IDENTITY();
        END
    END

    -- Update only provided fields
    UPDATE pm.PROPERTIES
    SET
        address = COALESCE(@Address, address),
        postal_code = COALESCE(@PostalCode, postal_code),
        city_id = COALESCE(@CityId, city_id),
        province_id = COALESCE(@ProvinceId, province_id),
        unit_type_id = COALESCE(@UnitTypeId, unit_type_id),
        management_start_date = COALESCE(@ManagementStartDate, management_start_date),
        length_of_service = COALESCE(@LengthOfService, length_of_service),
        status = COALESCE(@Status, status),
        storage_locker = COALESCE(@StorageLocker, storage_locker),
        parking_stall = COALESCE(@ParkingStall, parking_stall),
        remarks = COALESCE(@Remarks, remarks)
    WHERE property_id = @PropertyId;

    -- Return updated property
    EXEC pm.sp_GetPropertyById @PropertyId;
END
GO

-- ==============================================================
-- 4. DELETE PROPERTY
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_DeleteProperty
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM pm.PROPERTIES WHERE property_id = @PropertyId;

    SELECT 'Property deleted successfully' AS Message;
END
GO

-- ==============================================================
-- 5. GET PROPERTY KEYS/FOBS/BUZZER
-- ==============================================================

CREATE OR ALTER PROCEDURE pm.sp_GetPropertyAccess
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        k.key_id,
        k.property_id,
        p.building_no,
        p.unit_number,
        k.keys,
        k.fobs,
        k.buzzer_no
    FROM pm.KEYS_FOBS_BUZZER k
    INNER JOIN pm.PROPERTIES p ON k.property_id = p.property_id
    WHERE k.property_id = @PropertyId;
END
GO

CREATE OR ALTER PROCEDURE pm.sp_UpdatePropertyAccess
    @PropertyId INT,
    @Keys NVARCHAR(50) = NULL,
    @Fobs NVARCHAR(50) = NULL,
    @BuzzerNo NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if record exists
    IF EXISTS (SELECT 1 FROM pm.KEYS_FOBS_BUZZER WHERE property_id = @PropertyId)
    BEGIN
        UPDATE pm.KEYS_FOBS_BUZZER
        SET
            keys = COALESCE(@Keys, keys),
            fobs = COALESCE(@Fobs, fobs),
            buzzer_no = COALESCE(@BuzzerNo, buzzer_no)
        WHERE property_id = @PropertyId;
    END
    ELSE
    BEGIN
        INSERT INTO pm.KEYS_FOBS_BUZZER (property_id, keys, fobs, buzzer_no)
        VALUES (@PropertyId, @Keys, @Fobs, @BuzzerNo);
    END

    EXEC pm.sp_GetPropertyAccess @PropertyId;
END
GO
