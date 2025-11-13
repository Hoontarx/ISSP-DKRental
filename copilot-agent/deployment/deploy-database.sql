-- ==============================================================
-- DEPLOYMENT SCRIPT FOR COPILOT AGENT DATABASE COMPONENTS
-- ==============================================================
-- This script deploys all stored procedures and views needed
-- for the Property Management Copilot Agent
-- ==============================================================

PRINT 'Starting deployment of Property Management Copilot Agent components...';
PRINT '';

-- ==============================================================
-- 1. DEPLOY PROPERTY PROCEDURES
-- ==============================================================
PRINT '================================================';
PRINT '1. Deploying Property Management Stored Procedures...';
PRINT '================================================';

:r ../stored-procedures/01-properties-procedures.sql

PRINT 'Property procedures deployed successfully.';
PRINT '';

-- ==============================================================
-- 2. DEPLOY TENANT PROCEDURES
-- ==============================================================
PRINT '================================================';
PRINT '2. Deploying Tenant & Tenancy Stored Procedures...';
PRINT '================================================';

:r ../stored-procedures/02-tenants-procedures.sql

PRINT 'Tenant procedures deployed successfully.';
PRINT '';

-- ==============================================================
-- 3. DEPLOY OWNER PROCEDURES
-- ==============================================================
PRINT '================================================';
PRINT '3. Deploying Owner & Ownership Stored Procedures...';
PRINT '================================================';

:r ../stored-procedures/03-owners-procedures.sql

PRINT 'Owner procedures deployed successfully.';
PRINT '';

-- ==============================================================
-- 4. DEPLOY MAINTENANCE & INSPECTION PROCEDURES
-- ==============================================================
PRINT '================================================';
PRINT '4. Deploying Maintenance & Inspection Stored Procedures...';
PRINT '================================================';

:r ../stored-procedures/04-maintenance-inspections-procedures.sql

PRINT 'Maintenance & Inspection procedures deployed successfully.';
PRINT '';

-- ==============================================================
-- 5. DEPLOY FINANCIAL PROCEDURES
-- ==============================================================
PRINT '================================================';
PRINT '5. Deploying Financial Stored Procedures...';
PRINT '================================================';

:r ../stored-procedures/05-utilities-rent-taxes-procedures.sql

PRINT 'Financial procedures deployed successfully.';
PRINT '';

-- ==============================================================
-- 6. DEPLOY HELPER VIEWS
-- ==============================================================
PRINT '================================================';
PRINT '6. Deploying Helper Views...';
PRINT '================================================';

:r ../views/helper-views.sql

PRINT 'Helper views deployed successfully.';
PRINT '';

-- ==============================================================
-- 7. VERIFICATION
-- ==============================================================
PRINT '================================================';
PRINT '7. Verifying Deployment...';
PRINT '================================================';

-- Count stored procedures
DECLARE @ProcCount INT;
SELECT @ProcCount = COUNT(*)
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'pm'
  AND name LIKE 'sp_%';

PRINT 'Stored Procedures deployed: ' + CAST(@ProcCount AS VARCHAR(10));

-- Count views
DECLARE @ViewCount INT;
SELECT @ViewCount = COUNT(*)
FROM sys.views
WHERE SCHEMA_NAME(schema_id) = 'pm'
  AND name LIKE 'vw_%';

PRINT 'Views deployed: ' + CAST(@ViewCount AS VARCHAR(10));
PRINT '';

-- List all deployed procedures
PRINT 'Deployed Stored Procedures:';
SELECT name FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'pm'
  AND name LIKE 'sp_%'
ORDER BY name;

PRINT '';
PRINT 'Deployed Views:';
SELECT name FROM sys.views
WHERE SCHEMA_NAME(schema_id) = 'pm'
  AND name LIKE 'vw_%'
ORDER BY name;

PRINT '';
PRINT '================================================';
PRINT 'DEPLOYMENT COMPLETED SUCCESSFULLY!';
PRINT '================================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Deploy Azure Functions';
PRINT '2. Configure Copilot Studio Actions';
PRINT '3. Create Topics for common scenarios';
PRINT '4. Test with your sponsor team';
PRINT '';
