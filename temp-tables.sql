-- ==========================================
-- TEMP TABLE: Temp_B_Properties
-- ==========================================
CREATE TABLE dbo.Temp_B_Properties (
    [Building_No] NVARCHAR(255),
    [UNIT_TYPE] NVARCHAR(255),
    [UNIT_NUMBER] NVARCHAR(255),
    [ADDRESS] NVARCHAR(255),
    [City] NVARCHAR(255),
    [Province] NVARCHAR(255),
    [Postal_Code] NVARCHAR(255),
    [Management_Start_Date] NVARCHAR(255),
    [Length_of_Service] NVARCHAR(255),
    [Remarks] NVARCHAR(255),
    [Current_Previous_Vacant] NVARCHAR(255),
    [Tenant_1_First_Name] NVARCHAR(255),
    [Tenant_1_Last_Name] NVARCHAR(255),
    [Tenant_2_First_Name] NVARCHAR(255),
    [Tenant_2_Last_Name] NVARCHAR(255),
    [Tenant_3_First_Name] NVARCHAR(255),
    [Tenant_3_Last_Name] NVARCHAR(255),
    [Tenants_Email_1] NVARCHAR(255),
    [Tenants_Email_2] NVARCHAR(255),
    [Tenants_Email_3] NVARCHAR(255),
    [Tenants_Mobile_Number_1] NVARCHAR(255),
    [Tenants_Mobile_Number_2] NVARCHAR(255),
    [Tenants_Mobile_Number_3] NVARCHAR(255),
    [Policy_Number] NVARCHAR(255),
    [Tenant_Insurance_Start_Date] NVARCHAR(255),
    [Tenant_Insurance_End_Date] NVARCHAR(255),
    [Insurance_Remarks] NVARCHAR(255),
    [Owner_s_Name_1] NVARCHAR(255),
    [Owner_s_First_Name] NVARCHAR(255),
    [Owner_s_Last_Name] NVARCHAR(255),
    [Company_Name] NVARCHAR(255),
    [Owner_s_Name_2] NVARCHAR(255),
    [Owner_s_First_Name_2] NVARCHAR(255),
    [Owner_s_Last_Name_2] NVARCHAR(255),
    [Type_of_Owner] NVARCHAR(255),
    [Owners_Number_1] NVARCHAR(255),
    [Owners_Number_2] NVARCHAR(255),
    [Owner_s_Email_1] NVARCHAR(255),
    [Owner_s_Email_2] NVARCHAR(255),
    [Insurance_Number] NVARCHAR(255),
    [Owner_Insurance_Start_Date] NVARCHAR(255),
    [Owner_Insurance_End_Date] NVARCHAR(255),
    [Insurance_Remarks_2] NVARCHAR(255),
    [LEASE_START_DATE] NVARCHAR(255),
    [LEASE_END_DATE] NVARCHAR(255),
    [Term] NVARCHAR(255),
    [Lease_Status] NVARCHAR(255),
    [Date_of_Last_Rent_Increase] NVARCHAR(255),
    [RENT_2025] NVARCHAR(255),
    [RENT_2024] NVARCHAR(255),
    [RENT_2023] NVARCHAR(255),
    [RENT_2022] NVARCHAR(255),
    [RENT_2021] NVARCHAR(255),
    [RENT_2020] NVARCHAR(255),
    [RENT_2019] NVARCHAR(255),
    [RENT_2018] NVARCHAR(255),
    [RENT_2017] NVARCHAR(255),
    [RENT_2016] NVARCHAR(255),
    [SECURITY_DEPOSIT] NVARCHAR(255),
    [SECURITY_DEPOSIT_DATE] NVARCHAR(255),
    [PET_DEPOSIT] NVARCHAR(255),
    [PET_DEPOSIT_DATE] NVARCHAR(255),
    [STORAGE_LOCKER] NVARCHAR(255),
    [PARKING_STALL] NVARCHAR(255),
    [Keys] NVARCHAR(255),
    [FOB_s] NVARCHAR(255),
    [LAST_INSPECTION] NVARCHAR(255),
    [Need_Inspection] NVARCHAR(255),
    [Self_or_Site_Inspections] NVARCHAR(255),
    [INSPECTION_NOTES] NVARCHAR(255),
    [REPAIRS_AND_MAINTENANCE] NVARCHAR(255),
    [Fireplace_Yes_No_Review_zInspector] NVARCHAR(255),
    [BUZZER_NO] NVARCHAR(255),
    [STRATA_NO] NVARCHAR(255),
    [STRATA_LOT] NVARCHAR(255),
    [Strata_Manager_Name] NVARCHAR(255),
    [Strata_Manager_Contact_Number] NVARCHAR(255),
    [Strata_Manager_Email] NVARCHAR(255),
    [BC_Assessment_2021] NVARCHAR(255),
    [BC_Assessment_2022] NVARCHAR(255),
    [BC_Assessment_2023] NVARCHAR(255),
    [BC_Assessment_2024] NVARCHAR(255),
    [BC_Assessment_2025] NVARCHAR(255),
    [Building_Manager_Name] NVARCHAR(255),
    [Building_Manager_Phone_No] NVARCHAR(255),
    [Building_Manager_Email] NVARCHAR(255),
    [Concierge_Desk] NVARCHAR(255),
    [Concierge_Phone_No] NVARCHAR(255),
    [Concierge_Email] NVARCHAR(255)
);


-- ==========================================
-- TEMP TABLE: Temp_L_Properties
-- ==========================================
CREATE TABLE dbo.Temp_L_Properties (
    [CODE] NVARCHAR(255),
    [UNIT_TYPE] NVARCHAR(255),
    [UNIT_NUMBER] NVARCHAR(255),
    [ADDRESS] NVARCHAR(255),
    [City] NVARCHAR(255),
    [Postal_Code] NVARCHAR(255),
    [Status] NVARCHAR(255),
    [TENANT_NAME_1] NVARCHAR(255),
    [TENANT_NAME_2] NVARCHAR(255),
    [TENANT_NAME_3] NVARCHAR(255),
    [TENANT_EMAIL_1] NVARCHAR(255),
    [TENANT_EMAIL_2] NVARCHAR(255),
    [TENANT_CONTACT_1] NVARCHAR(255),
    [TENANT_CONTACT_2] NVARCHAR(255),
    [OWNER_NAME_1] NVARCHAR(255),
    [OWNER_FIRST_NAME_1] NVARCHAR(255),
    [OWNER_LAST_NAME_1] NVARCHAR(255),
    [OWNER_NAME_2] NVARCHAR(255),
    [OWNER_FIRST_NAME_2] NVARCHAR(255),
    [OWNER_LAST_NAME_2] NVARCHAR(255),
    [OWNER_CONTACT_1] NVARCHAR(255),
    [OWNER_CONTACT_2] NVARCHAR(255),
    [OWNER_EMAIL_1] NVARCHAR(255),
    [OWNER_EMAIL_2] NVARCHAR(255),
    [RENT_2023] NVARCHAR(255),
    [DEPOSIT_AMOUNT] NVARCHAR(255),
    [SECURITY_DEPOSIT_DATE] NVARCHAR(255),
    [PET_DEPOSIT] NVARCHAR(255),
    [END_OF_LEASE] NVARCHAR(255),
    [LAST_INSPECTION] NVARCHAR(255),
    [Building_Manage] NVARCHAR(255),
    [Building_Manager_Email] NVARCHAR(255),
    [Building_Manager_Number] NVARCHAR(255),
    [Strata_Manager] NVARCHAR(255),
    [Strata_Manager_Email] NVARCHAR(255),
    [Strata_Manager_Contact_Number] NVARCHAR(255),
    [Strata_No] NVARCHAR(255),
    [MAINTENANCE] NVARCHAR(255),
    [Notes] NVARCHAR(255)
);

-- ===============================================
-- TEMP TABLE: Temp_Move_In_Out
-- ===============================================
CREATE TABLE dbo.Temp_Move_In_Out (
    [Building_Code] NVARCHAR(255),
    [Building_No] NVARCHAR(255),
    [Unit_Type] NVARCHAR(255),
    [Tenant_Name] NVARCHAR(255),
    [Move_Out_InDate] NVARCHAR(255),
    [TENANT_AVAILABILITY] NVARCHAR(255),
    [Proposed_Date_TBC_by_David] NVARCHAR(255),
    [Confirmed_with_David] NVARCHAR(255),
    [Status] NVARCHAR(255),
    [Notify_Back_Office] NVARCHAR(255),
    [Security_Release] NVARCHAR(255),
    [Move_Out_Letter] NVARCHAR(255),
    [Move_in_Orientation] NVARCHAR(255),
    [Form_K] NVARCHAR(255),
    [zInspector] NVARCHAR(255)
);

-- ===============================================
-- TEMP TABLE: Temp_Split_Utilities
-- ===============================================
CREATE TABLE dbo.Temp_Split_Utilities (
    [Building_Code] NVARCHAR(255),
    [Tenant_Name_Upper_Main] NVARCHAR(255),
    [Split_Percentage_Upper_Main] NVARCHAR(255),
    [BC_Hydro_Upper_Main] NVARCHAR(255),
    [FortisBC_Upper_Main] NVARCHAR(255),
    [Total_Upper_Main] NVARCHAR(255),
    [Tenant_Name_Lower_Basement] NVARCHAR(255),
    [Split_Percentage_Lower_Basement] NVARCHAR(255),
    [BC_Hydro_Lower_Basement] NVARCHAR(255),
    [FortisBC_Lower_Basement] NVARCHAR(255),
    [Total_Lower_Basement] NVARCHAR(255),
    [Owner] NVARCHAR(255),
    [Total_Owner] NVARCHAR(255)
);

-- ===============================================
-- TEMP TABLE: Temp_Strata_Monitoring
-- ===============================================
CREATE TABLE dbo.Temp_Strata_Monitoring (
    [Date] NVARCHAR(255),
    [Unit_Number] NVARCHAR(255),
    [In_Suite_Access] NVARCHAR(255),
    [AGM_CM_SGM] NVARCHAR(255),
    [FOB_Audit] NVARCHAR(255)
);

-- ===============================================
-- TEMP TABLE: Temp_Taxes
-- ===============================================
CREATE TABLE dbo.Temp_Taxes (
    [Building_No] NVARCHAR(255),
    [UNIT_TYPE] NVARCHAR(255),
    [UNIT_NUMBER] NVARCHAR(255),
    [ADDRESS] NVARCHAR(255),
    [City] NVARCHAR(255),
    [Province] NVARCHAR(255),
    [Postal_Code] NVARCHAR(255),
    [Municipal_COV_EHT_Due_February_2nd] NVARCHAR(255),
    [Province_of_BC_Speculation_Vacancy_Tax_Due_March_31St] NVARCHAR(255),
    [Federal_Government_Underused_Housing_Tax_UHT_Return_Due_April_30th] NVARCHAR(255)
);

-- ===============================================
-- TEMP TABLE: Temp_Lists_of_Contractors
-- ===============================================
CREATE TABLE dbo.Temp_Lists_of_Contractors (
    [Name_of_Contact] NVARCHAR(255),
    [Contact_Number] NVARCHAR(255),
    [Email] NVARCHAR(255),
    [Services_Provided] NVARCHAR(255),
    [Notes] NVARCHAR(255)
);

-- ===============================================
-- TEMP TABLE: Temp_BC_Speculation
-- ===============================================
CREATE TABLE dbo.Temp_BC_Speculation (
    [Building_No] NVARCHAR(255),
    [Owners_Name] NVARCHAR(255),
    [Owner_First_Name] NVARCHAR(255),
    [Owner_Last_Name] NVARCHAR(255),
    [Owner_First_Name_2] NVARCHAR(255),
    [Owner_Last_Name_2] NVARCHAR(255),
    [Company_Name] NVARCHAR(255),
    [Owner_Email_1] NVARCHAR(255),
    [Owner_Email_2] NVARCHAR(255),
    [Tax_2025] NVARCHAR(255),
    [Tax_2024] NVARCHAR(255),
    [Tax_2023] NVARCHAR(255)
);

-- ===============================================
-- TEMP TABLE: Temp_BC_Assessment
-- ===============================================
CREATE TABLE dbo.Temp_BC_Assessment (
    [Property] NVARCHAR(255),
    [Assessment_2025] NVARCHAR(255)
);

-- ===============================================
-- TEMP TABLE: Temp_Inspections_w_Issues
-- ===============================================
CREATE TABLE dbo.Temp_Inspections_w_Issues (
    [Building_No] NVARCHAR(255),
    [Inspection] NVARCHAR(255),
    [Unit_No] NVARCHAR(255),
    [Description_of_Issue] NVARCHAR(255),
    [Action_Plan] NVARCHAR(255),
    [CO] NVARCHAR(255),
    [Status] NVARCHAR(255)
);
