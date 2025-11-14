-- ==============================================================
-- HELPER VIEWS FOR COPILOT AGENT
-- These views simplify common queries by pre-joining related tables
-- ==============================================================

-- ==============================================================
-- 1. PROPERTY OVERVIEW
-- ==============================================================

CREATE OR ALTER VIEW pm.vw_PropertyOverview
AS
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
    p.remarks,
    k.keys,
    k.fobs,
    k.buzzer_no
FROM pm.PROPERTIES p
LEFT JOIN pm.CITY c ON p.city_id = c.city_id
LEFT JOIN pm.PROVINCE pr ON p.province_id = pr.province_id
LEFT JOIN pm.PROPERTY_TYPE pt ON p.unit_type_id = pt.unit_type_id
LEFT JOIN pm.KEYS_FOBS_BUZZER k ON p.property_id = k.property_id;
GO

-- ==============================================================
-- 2. ACTIVE TENANCIES WITH TENANT DETAILS
-- ==============================================================

CREATE OR ALTER VIEW pm.vw_ActiveTenancies
AS
SELECT
    t.tenancy_id,
    t.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    c.city,
    pr.province,
    t.lease_start_date,
    t.lease_end_date,
    t.lease_status,
    t.term,
    t.security_deposit,
    t.pet_deposit,
    t.last_rent_increase,
    ti.policy_number AS insurance_policy,
    ti.insurance_start_date AS insurance_start,
    ti.insurance_end_date AS insurance_end,
    tn.tenant_id,
    tn.first_name AS tenant_first_name,
    tn.last_name AS tenant_last_name,
    tn.email AS tenant_email,
    tn.phone_number AS tenant_mobile,
    CASE
        WHEN t.lease_end_date IS NOT NULL AND t.lease_end_date < GETDATE() THEN 'Expired'
        WHEN t.lease_end_date IS NOT NULL AND DATEDIFF(day, GETDATE(), t.lease_end_date) <= 90 THEN 'Expiring Soon'
        ELSE 'Active'
    END AS lease_health_status
FROM pm.TENANCY t
INNER JOIN pm.PROPERTIES p ON t.property_id = p.property_id
LEFT JOIN pm.CITY c ON p.city_id = c.city_id
LEFT JOIN pm.PROVINCE pr ON p.province_id = pr.province_id
LEFT JOIN pm.TENANT_INSURANCE ti ON t.insurance_id = ti.insurance_id
LEFT JOIN pm.TENANT tn ON t.tenancy_id = tn.tenancy_id
WHERE t.lease_status = 'Active' OR t.lease_end_date >= DATEADD(day, -90, GETDATE());
GO

-- ==============================================================
-- 3. PROPERTY OWNERSHIP
-- ==============================================================

CREATE OR ALTER VIEW pm.vw_PropertyOwnership
AS
SELECT
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    o.owner_id,
    o.first_name AS owner_first_name,
    o.last_name AS owner_last_name,
    o.company_name AS owner_company,
    o.type_of_owner,
    o.phone_number AS owner_phone,
    o.email AS owner_email,
    c.first_name AS care_of_first_name,
    c.last_name AS care_of_last_name,
    c.phone_number AS care_of_phone,
    c.email AS care_of_email
FROM pm.PROPERTIES p
LEFT JOIN pm.OWNERSHIP ow ON p.property_id = ow.frn_property_id
LEFT JOIN pm.OWNERS o ON ow.frn_owner_id = o.owner_id
LEFT JOIN pm.CARE_OF c ON o.care_of = c.care_of_id;
GO

-- ==============================================================
-- 4. MAINTENANCE OVERVIEW
-- ==============================================================

CREATE OR ALTER VIEW pm.vw_MaintenanceOverview
AS
SELECT
    m.maintenance_id,
    m.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    c.city,
    m.description,
    m.action_plan,
    m.status,
    m.assigned_to,
    cnt.contractor_id,
    cnt.company_name AS contractor_company,
    cnt.contact_name AS contractor_contact,
    cnt.contact_number AS contractor_phone,
    cnt.email AS contractor_email,
    cnt.specialization AS contractor_specialization,
    CASE
        WHEN m.status = 'Open' THEN 1
        WHEN m.status = 'In Progress' THEN 2
        WHEN m.status = 'Pending' THEN 3
        ELSE 4
    END AS priority_order
FROM pm.MAINTENANCE m
INNER JOIN pm.PROPERTIES p ON m.property_id = p.property_id
LEFT JOIN pm.CITY c ON p.city_id = c.city_id
LEFT JOIN pm.CONTRACTORS cnt ON m.contractor_id = cnt.contractor_id;
GO

-- ==============================================================
-- 5. INSPECTION STATUS
-- ==============================================================

CREATE OR ALTER VIEW pm.vw_InspectionStatus
AS
SELECT
    i.inspection_id,
    i.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    c.city,
    it.inspection_type,
    i.last_inspection_date,
    i.need_inspection,
    i.inspection_notes,
    i.repairs_maintenance,
    i.follow_up_date,
    DATEDIFF(day, i.last_inspection_date, GETDATE()) AS days_since_inspection,
    CASE
        WHEN i.follow_up_date IS NOT NULL AND i.follow_up_date < GETDATE() THEN 'Overdue'
        WHEN i.follow_up_date IS NOT NULL AND DATEDIFF(day, GETDATE(), i.follow_up_date) <= 30 THEN 'Due Soon'
        WHEN i.need_inspection = 'Yes' THEN 'Needed'
        ELSE 'Current'
    END AS inspection_status
FROM pm.INSPECTIONS i
INNER JOIN pm.PROPERTIES p ON i.property_id = p.property_id
LEFT JOIN pm.CITY c ON p.city_id = c.city_id
INNER JOIN pm.INSPECTION_TYPE it ON i.inspection_type_id = it.inspection_type_id;
GO

-- ==============================================================
-- 6. FINANCIAL OVERVIEW
-- ==============================================================

CREATE OR ALTER VIEW pm.vw_FinancialOverview
AS
SELECT
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    r.rent_amount AS current_rent,
    r.effective_date AS rent_effective_date,
    t.municipal_eht,
    t.bc_speculation_tax,
    t.federal_uht,
    (COALESCE(t.municipal_eht, 0) + COALESCE(t.bc_speculation_tax, 0) + COALESCE(t.federal_uht, 0)) AS total_taxes,
    a.assessed_value AS latest_assessment,
    a.[year] AS assessment_year
FROM pm.PROPERTIES p
LEFT JOIN (
    SELECT property_id, rent_amount, effective_date,
           ROW_NUMBER() OVER (PARTITION BY property_id ORDER BY effective_date DESC) AS rn
    FROM pm.RENT
    WHERE effective_date <= GETDATE() AND (end_date IS NULL OR end_date >= GETDATE())
) r ON p.property_id = r.property_id AND r.rn = 1
LEFT JOIN pm.TAXES t ON p.property_id = t.property_id
LEFT JOIN (
    SELECT property_id, assessed_value, [year],
           ROW_NUMBER() OVER (PARTITION BY property_id ORDER BY [year] DESC) AS rn
    FROM pm.BC_ASSESSMENTS
) a ON p.property_id = a.property_id AND a.rn = 1;
GO

-- ==============================================================
-- 7. UPCOMING EVENTS & EXPIRATIONS
-- ==============================================================

CREATE OR ALTER VIEW pm.vw_UpcomingEvents
AS
SELECT
    'Lease Expiration' AS event_type,
    t.tenancy_id AS related_id,
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    t.lease_end_date AS event_date,
    DATEDIFF(day, GETDATE(), t.lease_end_date) AS days_until,
    'Lease ending for ' + tn.first_name + ' ' + tn.last_name AS description
FROM pm.TENANCY t
INNER JOIN pm.PROPERTIES p ON t.property_id = p.property_id
LEFT JOIN pm.TENANT tn ON t.tenancy_id = tn.tenancy_id
WHERE t.lease_end_date IS NOT NULL AND t.lease_end_date BETWEEN GETDATE() AND DATEADD(day, 90, GETDATE())

UNION ALL

SELECT
    'Tenant Insurance Expiration' AS event_type,
    ti.insurance_id AS related_id,
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    ti.insurance_end_date AS event_date,
    DATEDIFF(day, GETDATE(), ti.insurance_end_date) AS days_until,
    'Tenant insurance expiring - Policy: ' + ti.policy_number AS description
FROM pm.TENANT_INSURANCE ti
INNER JOIN pm.TENANCY t ON ti.insurance_id = t.insurance_id
INNER JOIN pm.PROPERTIES p ON t.property_id = p.property_id
WHERE ti.insurance_end_date IS NOT NULL AND ti.insurance_end_date BETWEEN GETDATE() AND DATEADD(day, 60, GETDATE())

UNION ALL

SELECT
    'Owner Insurance Expiration' AS event_type,
    oi.owner_insurance_id AS related_id,
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    oi.insurance_end_date AS event_date,
    DATEDIFF(day, GETDATE(), oi.insurance_end_date) AS days_until,
    'Owner insurance expiring - Policy: ' + oi.policy_number AS description
FROM pm.OWNER_INSURANCE oi
INNER JOIN pm.PROPERTIES p ON oi.property_id = p.property_id
WHERE oi.insurance_end_date IS NOT NULL AND oi.insurance_end_date BETWEEN GETDATE() AND DATEADD(day, 60, GETDATE())

UNION ALL

SELECT
    'Inspection Follow-up' AS event_type,
    i.inspection_id AS related_id,
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    i.follow_up_date AS event_date,
    DATEDIFF(day, GETDATE(), i.follow_up_date) AS days_until,
    it.inspection_type + ' inspection follow-up' AS description
FROM pm.INSPECTIONS i
INNER JOIN pm.PROPERTIES p ON i.property_id = p.property_id
INNER JOIN pm.INSPECTION_TYPE it ON i.inspection_type_id = it.inspection_type_id
WHERE i.follow_up_date IS NOT NULL AND i.follow_up_date BETWEEN GETDATE() AND DATEADD(day, 30, GETDATE())

UNION ALL

SELECT
    'Move In/Out' AS event_type,
    m.move_id AS related_id,
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    m.move_date AS event_date,
    DATEDIFF(day, GETDATE(), m.move_date) AS days_until,
    CASE WHEN m.move_type_id = 1 THEN 'Move In' ELSE 'Move Out' END + ' scheduled' AS description
FROM pm.MOVE m
INNER JOIN pm.TENANCY t ON m.tenancy_id = t.tenancy_id
INNER JOIN pm.PROPERTIES p ON t.property_id = p.property_id
WHERE m.move_date IS NOT NULL AND m.move_date BETWEEN GETDATE() AND DATEADD(day, 30, GETDATE());
GO

-- ==============================================================
-- 8. OPEN ISSUES & TASKS
-- ==============================================================

CREATE OR ALTER VIEW pm.vw_OpenIssues
AS
SELECT
    'Maintenance' AS issue_type,
    m.maintenance_id AS issue_id,
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    m.description,
    m.status,
    m.assigned_to,
    NULL AS date_logged
FROM pm.MAINTENANCE m
INNER JOIN pm.PROPERTIES p ON m.property_id = p.property_id
WHERE m.status IN ('Open', 'In Progress', 'Pending')

UNION ALL

SELECT
    'Inspection Issue' AS issue_type,
    ii.issue_id,
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    ii.description_of_issue AS description,
    ii.status,
    ii.checked_off_by AS assigned_to,
    ii.date_logged
FROM pm.INSPECTION_ISSUES ii
INNER JOIN pm.INSPECTIONS i ON ii.inspection_id = i.inspection_id
INNER JOIN pm.PROPERTIES p ON i.property_id = p.property_id
WHERE ii.status IN ('Open', 'In Progress');
GO

-- ==============================================================
-- 9. COMPLETE PROPERTY DASHBOARD
-- ==============================================================

CREATE OR ALTER VIEW pm.vw_PropertyDashboard
AS
SELECT
    p.property_id,
    p.building_no,
    p.unit_number,
    p.address,
    c.city,
    pr.province,
    pt.unit_type,
    p.status AS property_status,

    -- Current Tenant Info
    t.tenancy_id,
    t.lease_status,
    t.lease_start_date,
    t.lease_end_date,
    DATEDIFF(day, GETDATE(), t.lease_end_date) AS days_until_lease_end,

    -- Current Rent
    r.rent_amount AS current_rent,

    -- Owner Info
    o.owner_id,
    COALESCE(o.company_name, o.first_name + ' ' + o.last_name) AS owner_name,
    o.email AS owner_email,
    o.phone_number AS owner_phone,

    -- Counts
    (SELECT COUNT(*) FROM pm.MAINTENANCE m WHERE m.property_id = p.property_id AND m.status IN ('Open', 'In Progress')) AS open_maintenance_count,
    (SELECT COUNT(*) FROM pm.INSPECTIONS i WHERE i.property_id = p.property_id AND i.need_inspection = 'Yes') AS inspections_needed_count

FROM pm.PROPERTIES p
LEFT JOIN pm.CITY c ON p.city_id = c.city_id
LEFT JOIN pm.PROVINCE pr ON p.province_id = pr.province_id
LEFT JOIN pm.PROPERTY_TYPE pt ON p.unit_type_id = pt.unit_type_id
LEFT JOIN pm.TENANCY t ON p.property_id = t.property_id AND t.lease_status = 'Active'
LEFT JOIN (
    SELECT property_id, rent_amount,
           ROW_NUMBER() OVER (PARTITION BY property_id ORDER BY effective_date DESC) AS rn
    FROM pm.RENT
    WHERE effective_date <= GETDATE() AND (end_date IS NULL OR end_date >= GETDATE())
) r ON p.property_id = r.property_id AND r.rn = 1
LEFT JOIN pm.OWNERSHIP ow ON p.property_id = ow.frn_property_id
LEFT JOIN pm.OWNERS o ON ow.frn_owner_id = o.owner_id;
GO
