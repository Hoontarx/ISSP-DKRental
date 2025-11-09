---PROPERTIES INSERTION----

INSERT INTO pm.CITY (city)
SELECT DISTINCT [City]
FROM dbo.Temp_B_Properties
WHERE City IS NOT NULL;

INSERT INTO pm.PROPERTY_TYPE (unit_type)
SELECT DISTINCT [UNIT_TYPE]
FROM dbo.Temp_B_Properties
WHERE UNIT_TYPE IS NOT NULL;

INSERT INTO pm.PROVINCE (province)
SELECT DISTINCT [Province]
FROM dbo.Temp_B_Properties
WHERE Province IS NOT NULL;


INSERT INTO pm.PROPERTIES (
    building_no,
    unit_type_id,
    unit_number,
    address,
    city_id,
    province_id,
    postal_code,
    length_of_service,
    management_start_date,
    storage_locker,
    parking_stall,
    remarks
)
SELECT DISTINCT
    t.Building_No,
    pt.unit_type_id,
    t.UNIT_NUMBER,
    t.address,
    c.city_id,
    p.province_id,
    t.Postal_Code,
    t.Length_of_Service,
    t.Management_Start_Date,
    t.STORAGE_LOCKER,
    t.PARKING_STALL,
    t.Remarks
FROM dbo.Temp_B_Properties AS t
JOIN pm.CITY AS c ON c.city = t.City
JOIN pm.PROVINCE AS p ON p.province = t.Province
JOIN pm.PROPERTY_TYPE AS pt ON pt.unit_type = t.UNIT_TYPE
WHERE t.Building_No IS NOT NULL
  AND t.UNIT_TYPE IS NOT NULL
  AND t.UNIT_NUMBER IS NOT NULL
  AND t.ADDRESS IS NOT NULL
  AND t.City IS NOT NULL
  AND t.Province IS NOT NULL;

----TENANT----

INSERT INTO pm.TENANT_INSURANCE(
    policy_number,
    insurance_start_date,
    insurance_end_date,
    remarks
)
SELECT DISTINCT
    t.Policy_Number,
    t.Tenant_Insurance_Start_Date,
    t.Tenant_Insurance_End_Date,
    t.Insurance_Remarks
FROM dbo.Temp_B_Properties AS t
WHERE TRY_CONVERT(DATE, t.Tenant_Insurance_Start_Date) IS NOT NULL
  AND TRY_CONVERT(DATE, t.Tenant_Insurance_End_Date) IS NOT NULL

INSERT INTO pm.TENANCY(
    insurance_id,
    property_id,
    lease_start_date,
    lease_end_date,
    lease_status,
    term,
    security_deposit,
    security_deposit_date,
    pet_deposit,
    pet_deposit_date,
    last_rent_increase
)
SELECT 
    insurance_id,
    property_id,
    lease_start_date,
    lease_end_date,
    lease_status,
    term,
    security_deposit,
    security_deposit_date,
    pet_deposit,
    pet_deposit_date,
    last_rent_increase
FROM (
    SELECT DISTINCT
        ti.insurance_id,
        p.property_id,
        TRY_CONVERT(DATE, t.LEASE_START_DATE) AS lease_start_date,
        TRY_CONVERT(DATE, t.LEASE_END_DATE) AS lease_end_date,
        t.Lease_Status AS lease_status,
        t.Term AS term,
        TRY_CONVERT(DECIMAL(10,2), t.SECURITY_DEPOSIT) AS security_deposit,
        TRY_CONVERT(DATE, t.SECURITY_DEPOSIT_DATE) AS security_deposit_date,
        TRY_CONVERT(DECIMAL(10,2), t.PET_DEPOSIT) AS pet_deposit,
        TRY_CONVERT(DATE, t.PET_DEPOSIT_DATE) AS pet_deposit_date,
        TRY_CONVERT(DATE, t.Date_of_Last_Rent_Increase) AS last_rent_increase,
        ROW_NUMBER() OVER (
            PARTITION BY p.property_id, TRY_CONVERT(DATE, t.LEASE_START_DATE)
            ORDER BY t.LEASE_START_DATE
        ) AS rn
    FROM dbo.Temp_B_Properties AS t
    JOIN pm.PROPERTIES AS p
        ON p.building_no = t.Building_No
        AND p.unit_number = t.UNIT_NUMBER
    JOIN pm.TENANT_INSURANCE AS ti
        ON ti.policy_number = t.Policy_Number
    WHERE NOT EXISTS (
        SELECT 1
        FROM pm.TENANCY AS tn
        WHERE tn.property_id = p.property_id
          AND tn.lease_start_date = TRY_CONVERT(DATE, t.LEASE_START_DATE)
    )
) AS sub
WHERE rn = 1
  AND lease_start_date IS NOT NULL
  AND lease_end_date IS NOT NULL;


INSERT INTO [pm].[TENANT](
    tenancy_id,
    first_name,
    last_name,
    phone_number,
    email
)
SELECT 
    t.tenancy_id,
    tbp.Tenant_1_First_Name AS first_name,
    tbp.Tenant_1_Last_Name AS last_name,
    tbp.Tenants_Mobile_Number_1 AS phone_number,
    tbp.Tenants_Email_1 AS email
FROM dbo.Temp_B_Properties AS tbp
JOIN pm.TENANCY AS t
    ON t.property_id = (
           SELECT p.property_id
           FROM pm.PROPERTIES AS p
           WHERE p.building_no = tbp.Building_No
             AND p.unit_number = tbp.Unit_Number
       )
    AND t.lease_start_date = TRY_CONVERT(DATE, tbp.LEASE_START_DATE)
WHERE tbp.Tenant_1_First_Name IS NOT NULL
  AND tbp.Tenant_1_Last_Name IS NOT NULL

UNION ALL

SELECT 
    t.tenancy_id,
    tbp.Tenant_2_First_Name AS first_name,
    tbp.Tenant_2_Last_Name AS last_name,
    tbp.Tenants_Mobile_Number_2 AS phone_number,
    tbp.Tenants_Email_2 AS email
FROM dbo.Temp_B_Properties AS tbp
JOIN pm.TENANCY AS t
    ON t.property_id = (
           SELECT p.property_id
           FROM pm.PROPERTIES AS p
           WHERE p.building_no = tbp.Building_No
             AND p.unit_number = tbp.Unit_Number
       )
    AND t.lease_start_date = TRY_CONVERT(DATE, tbp.LEASE_START_DATE)
WHERE tbp.Tenant_2_First_Name IS NOT NULL
  AND tbp.Tenant_2_Last_Name IS NOT NULL

UNION ALL

SELECT 
    t.tenancy_id,
    tbp.Tenant_3_First_Name AS first_name,
    tbp.Tenant_3_Last_Name AS last_name,
    tbp.Tenants_Mobile_Number_3 AS phone_number,
    tbp.Tenants_Email_3 AS email
FROM dbo.Temp_B_Properties AS tbp
JOIN pm.TENANCY AS t
    ON t.property_id = (
           SELECT p.property_id
           FROM pm.PROPERTIES AS p
           WHERE p.building_no = tbp.Building_No
             AND p.unit_number = tbp.Unit_Number
       )
    AND t.lease_start_date = TRY_CONVERT(DATE, tbp.LEASE_START_DATE)
WHERE tbp.Tenant_3_First_Name IS NOT NULL
  AND tbp.Tenant_3_Last_Name IS NOT NULL;




--- Owner INSERTION----

INSERT INTO pm.OWNER_INSURANCE(
    property_id,
    policy_number,
    insurance_start_date,
    insurance_end_date,
    remarks
)
SELECT DISTINCT
    p.property_id,
    t.Insurance_Number AS policy_number,
    TRY_CONVERT(DATE, t.Owner_Insurance_Start_Date) AS insurance_start_date,
    TRY_CONVERT(DATE, t.Owner_Insurance_End_Date) AS insurance_end_date,
    t.Insurance_Remarks_2 AS remarks
FROM dbo.Temp_B_Properties AS t
JOIN pm.PROPERTIES AS p
    ON p.building_no = t.Building_No
   AND p.unit_number = t.Unit_Number
WHERE TRY_CONVERT(DATE, t.Owner_Insurance_Start_Date) IS NOT NULL
  AND TRY_CONVERT(DATE, t.Owner_Insurance_End_Date) IS NOT NULL
  AND t.Insurance_Number IS NOT NULL;

INSERT INTO pm.CARE_OF(
    first_name,
    last_name,
    phone_number,
    email
)
SELECT DISTINCT
    t.Owner_s_First_Name AS first_name,
    t.Owner_s_Last_Name AS last_name,
    t.Owners_Number_1 AS phone_number,
    t.Owner_s_Email_1 AS email
FROM dbo.Temp_B_Properties AS t
WHERE t.Company_Name IS NOT NULL
  AND t.Owner_s_First_Name IS NOT NULL
  AND t.Owner_s_Last_Name IS NOT NULL

UNION ALL

SELECT DISTINCT
    t.Owner_s_First_Name_2 AS first_name,
    t.Owner_s_Last_Name_2 AS last_name,
    t.Owners_Number_2 AS phone_number,
    t.Owner_s_Email_2 AS email
FROM dbo.Temp_B_Properties AS t
WHERE t.Company_Name IS NOT NULL
  AND t.Owner_s_First_Name_2 IS NOT NULL
  AND t.Owner_s_Last_Name_2 IS NOT NULL;



INSERT INTO pm.OWNERS (
    first_name,
    last_name,
    company_name,
    type_of_owner,
    phone_number,
    email,
    care_of
)
SELECT DISTINCT
    NULL AS first_name,
    NULL AS last_name,
    t.Company_Name AS company_name,
    t.Type_of_Owner AS type_of_owner,
    NULL AS phone_number,
    NULL AS email,
    co.care_of_id AS care_of
FROM dbo.Temp_B_Properties AS t
JOIN pm.CARE_OF AS co
    ON co.first_name = t.Owner_s_First_Name
   AND co.last_name  = t.Owner_s_Last_Name
WHERE t.Company_Name IS NOT NULL

UNION ALL

SELECT DISTINCT
    t.Owner_s_First_Name AS first_name,
    t.Owner_s_Last_Name AS last_name,
    NULL AS company_name,
    t.Type_of_Owner AS type_of_owner,
    t.Owners_Number_1 AS phone_number,
    t.Owner_s_Email_1 AS email,
    NULL AS care_of
FROM dbo.Temp_B_Properties AS t
WHERE t.Company_Name IS NULL
  AND t.Owner_s_First_Name IS NOT NULL
  AND t.Owner_s_Last_Name IS NOT NULL

UNION ALL

SELECT DISTINCT
    t.Owner_s_First_Name_2 AS first_name,
    t.Owner_s_Last_Name_2 AS last_name,
    NULL AS company_name,
    t.Type_of_Owner AS type_of_owner,
    t.Owners_Number_2 AS phone_number,
    t.Owner_s_Email_2 AS email,
    NULL AS care_of
FROM dbo.Temp_B_Properties AS t
WHERE t.Company_Name IS NULL
  AND t.Owner_s_First_Name_2 IS NOT NULL
  AND t.Owner_s_Last_Name_2 IS NOT NULL;

INSERT INTO pm.OWNERSHIP (frn_owner_id, frn_property_id)
SELECT DISTINCT
    o.owner_id,
    p.property_id
FROM dbo.Temp_B_Properties AS t
-- unpivot multiple owners
CROSS APPLY (VALUES
    (t.Owner_s_First_Name, t.Owner_s_Last_Name),
    (t.Owner_s_First_Name_2, t.Owner_s_Last_Name_2)
    ) AS owners(first_name, last_name)
JOIN pm.OWNERS AS o
    ON o.first_name = owners.first_name
   AND o.last_name  = owners.last_name
JOIN pm.PROPERTIES AS p
    ON p.building_no = t.Building_No
   AND p.unit_number = t.Unit_Number
WHERE owners.first_name IS NOT NULL
  AND owners.last_name IS NOT NULL

UNION ALL

-- Company owners using care_of
SELECT DISTINCT
    o.owner_id,
    p.property_id
FROM dbo.Temp_B_Properties AS t
JOIN pm.OWNERS AS o
    ON o.company_name = t.Company_Name
   AND o.care_of IS NOT NULL
JOIN pm.PROPERTIES AS p
    ON p.building_no = t.Building_No
   AND p.unit_number = t.Unit_Number
WHERE t.Company_Name IS NOT NULL;


--- MOVE INSERTION----

-- CANT BE DONE UNLESS TEMP CORRECTED

--- RENT INSERTION----

INSERT INTO pm.RENT (
    property_id,
    rent_year,
    rent_amount,
    effective_date,
    end_date
)
SELECT 
    p.property_id,
    v.rent_year,
    v.rent_amount,
    DATEFROMPARTS(v.rent_year, 1, 1) AS effective_date,  -- use Jan 1 of the rent year
    NULL AS end_date
FROM dbo.Temp_B_Properties AS t
JOIN pm.PROPERTIES AS p
    ON p.building_no = t.Building_No
   AND p.unit_number = t.Unit_Number
CROSS APPLY (VALUES
    (2016, TRY_CONVERT(DECIMAL(10,2), t.Rent_2023)),
    (2017, TRY_CONVERT(DECIMAL(10,2), t.Rent_2023)),
    (2018, TRY_CONVERT(DECIMAL(10,2), t.Rent_2023)),
    (2019, TRY_CONVERT(DECIMAL(10,2), t.Rent_2023)),
    (2020, TRY_CONVERT(DECIMAL(10,2), t.Rent_2023)),
    (2021, TRY_CONVERT(DECIMAL(10,2), t.Rent_2023)),
    (2022, TRY_CONVERT(DECIMAL(10,2), t.Rent_2023)),
    (2023, TRY_CONVERT(DECIMAL(10,2), t.Rent_2023)),
    (2024, TRY_CONVERT(DECIMAL(10,2), t.Rent_2024)),
    (2025, TRY_CONVERT(DECIMAL(10,2), t.Rent_2025))
) AS v(rent_year, rent_amount)
WHERE v.rent_amount IS NOT NULL
  AND NOT EXISTS (
        SELECT 1
        FROM pm.RENT AS r
        WHERE r.property_id = p.property_id
          AND r.rent_year = v.rent_year
  );




--- INSERTION----
--- INSERTION----
--- INSERTION----
--- INSERTION----
--- INSERTION----
--- INSERTION----
--- INSERTION----
--- INSERTION----
--- INSERTION----