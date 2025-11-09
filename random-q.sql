SELECT
    p.building_no,
    p.unit_number,
    pt.unit_type,
    t.first_name AS tenant_first_name,
    t.last_name AS tenant_last_name
FROM pm.PROPERTIES AS p
LEFT JOIN pm.PROPERTY_TYPE AS pt
    ON p.unit_type_id = pt.unit_type_id
LEFT JOIN pm.TENANCY AS tn
    ON tn.property_id = p.property_id
LEFT JOIN pm.TENANT AS t
    ON t.tenancy_id = tn.tenancy_id
ORDER BY p.building_no, p.unit_number;