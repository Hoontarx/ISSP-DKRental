# Property Management Copilot Agent

## Overview

This solution provides a comprehensive database management layer for your Property Management system, enabling non-technical users to interact with the database through Microsoft Copilot Studio using natural language.

## Architecture

```
┌─────────────────────┐
│  Copilot Studio     │
│  (Natural Language) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Azure Functions    │
│  (HTTP Triggers)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  SQL Stored Procs   │
│  & Helper Views     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Azure SQL Database │
│  (Property Mgmt DB) │
└─────────────────────┘
```

## What's Included

### 1. **Stored Procedures** (`/stored-procedures/`)
Complete CRUD operations for all entities:
- **Properties**: Search, create, update, access management
- **Tenants & Tenancy**: Lease management, tenant info, move in/out
- **Owners & Ownership**: Owner management, insurance tracking
- **Maintenance & Inspections**: Work orders, contractor management, inspections
- **Financial**: Rent history, taxes, assessments, utilities

### 2. **Helper Views** (`/views/`)
Pre-built views for common queries:
- `vw_PropertyOverview`: Complete property details
- `vw_ActiveTenancies`: Current tenant information
- `vw_PropertyOwnership`: Owner-property relationships
- `vw_MaintenanceOverview`: Open maintenance requests
- `vw_InspectionStatus`: Inspection tracking
- `vw_FinancialOverview`: Rent, taxes, assessments
- `vw_UpcomingEvents`: Expirations and deadlines
- `vw_OpenIssues`: All open tasks
- `vw_PropertyDashboard`: Complete property dashboard

### 3. **Azure Functions** (`/azure-functions/`)
HTTP-triggered functions exposing database operations:
- **PropertyFunctions**: Property CRUD and dashboard
- **TenantFunctions**: Tenancy and tenant management
- **MaintenanceFunctions**: Maintenance and inspection operations
- **QueryFunctions**: Views, reports, and financial data

### 4. **OpenAPI Specification** (`openapi-spec.json`)
Complete OpenAPI 3.0 specification for easy integration:
- **Import directly into Copilot Studio** as a custom connector
- **18+ operations** fully documented with schemas
- **Ready to use** - just update your Function App URL
- **No Power Automate required** - perfect for restricted environments

📘 **See [CUSTOM_CONNECTOR_GUIDE.md](CUSTOM_CONNECTOR_GUIDE.md) for step-by-step setup**

## Deployment Guide

> **💡 Quick Start Options:**
> - **Option A (Recommended)**: Use the OpenAPI specification to create a custom connector → See [CUSTOM_CONNECTOR_GUIDE.md](CUSTOM_CONNECTOR_GUIDE.md)
> - **Option B**: Manually create Actions for each endpoint → See [COPILOT_STUDIO_SETUP.md](COPILOT_STUDIO_SETUP.md)

### Step 1: Deploy Database Components

1. **Connect to Azure SQL Database**:
   ```bash
   sqlcmd -S your-server.database.windows.net -d your-database -U your-username -P your-password
   ```

2. **Deploy Stored Procedures** (in order):
   ```sql
   -- Execute these files in order:
   :r stored-procedures/01-properties-procedures.sql
   :r stored-procedures/02-tenants-procedures.sql
   :r stored-procedures/03-owners-procedures.sql
   :r stored-procedures/04-maintenance-inspections-procedures.sql
   :r stored-procedures/05-utilities-rent-taxes-procedures.sql
   ```

3. **Deploy Views**:
   ```sql
   :r views/helper-views.sql
   ```

### Step 2: Deploy Azure Functions

1. **Update Connection String**:
   - Edit `azure-functions/local.settings.json`
   - Update `SqlConnectionString` with your Azure SQL connection string

2. **Build and Test Locally**:
   ```bash
   cd azure-functions
   dotnet build
   func start
   ```

3. **Deploy to Azure**:
   ```bash
   # Create Function App (if not exists)
   az functionapp create \
     --resource-group your-rg \
     --consumption-plan-location westus \
     --runtime dotnet-isolated \
     --functions-version 4 \
     --name your-function-app-name \
     --storage-account your-storage-account

   # Deploy
   func azure functionapp publish your-function-app-name
   ```

4. **Configure Application Settings**:
   ```bash
   az functionapp config appsettings set \
     --name your-function-app-name \
     --resource-group your-rg \
     --settings SqlConnectionString="Server=tcp:your-server.database.windows.net,1433;..."
   ```

### Step 3: Configure Copilot Studio

**Choose your integration method:**

- **🚀 Recommended: Custom Connector** - Import the OpenAPI spec for automatic configuration of all 18+ operations
  - Follow the complete guide: [CUSTOM_CONNECTOR_GUIDE.md](CUSTOM_CONNECTOR_GUIDE.md)
  - Faster setup, less manual work
  - All operations pre-configured with proper schemas

- **⚙️ Manual Setup: Individual Actions** - Create each action manually
  - Follow the complete guide: [COPILOT_STUDIO_SETUP.md](COPILOT_STUDIO_SETUP.md)
  - More control over each operation
  - Good for learning or customizing specific operations

#### Quick Example: Manual Action Setup

If you choose manual setup, here's an example:

1. **Go to Copilot Studio** → Your Agent → **Actions** → **Add Action**

2. **Create Action from HTTP Endpoint**:

   Example: "Get Properties"
   - **Name**: GetProperties
   - **Description**: Search for properties by city, province, status, or unit type
   - **URL**: `https://your-function-app.azurewebsites.net/api/GetProperties`
   - **Method**: GET
   - **Parameters**:
     - `city` (optional): City name
     - `province` (optional): Province name
     - `status` (optional): Property status
     - `unitType` (optional): Unit type
   - **Authentication**: Function Key

3. **Repeat for all functions** (see API Reference below)

#### B. Create Topics for Common Scenarios

**Example Topic: "Find Property Information"**
```
Trigger Phrases:
- "Show me properties in [city]"
- "What properties do we have in [location]"
- "Find properties with status [status]"

Topic Flow:
1. Extract entities (city, status, etc.)
2. Call GetProperties action
3. Format and display results
```

**Example Topic: "Check Upcoming Expirations"**
```
Trigger Phrases:
- "What leases are expiring soon?"
- "Show me upcoming events"
- "What needs my attention?"

Topic Flow:
1. Call GetUpcomingEvents action
2. Filter by event type if specified
3. Display formatted list with dates
```

**Example Topic: "Create Maintenance Request"**
```
Trigger Phrases:
- "Create a maintenance request"
- "Log a maintenance issue for [property]"
- "Report a problem at [address]"

Topic Flow:
1. Ask for property ID/address
2. Ask for description
3. Ask for action plan (optional)
4. Call CreateMaintenance action
5. Confirm creation
```

#### C. Enable Generative AI Features

1. Go to **Settings** → **Generative AI**
2. Enable **Generative answers**
3. Add your database views as knowledge sources for better context

## API Reference

### Property Functions

#### GET /api/GetProperties
Search properties
- **Parameters**: `city`, `province`, `status`, `unitType` (all optional)
- **Returns**: List of properties matching criteria

#### GET /api/GetPropertyById
Get specific property
- **Parameters**: `propertyId` (required)
- **Returns**: Property details

#### POST /api/CreateProperty
Create new property
- **Body**:
  ```json
  {
    "buildingNo": "123",
    "unitNumber": "101",
    "address": "123 Main St",
    "cityName": "Vancouver",
    "provinceName": "BC",
    "status": "Active"
  }
  ```

#### PUT /api/UpdateProperty
Update property
- **Body**:
  ```json
  {
    "propertyId": 1,
    "status": "Rented",
    "remarks": "Updated notes"
  }
  ```

### Tenant Functions

#### GET /api/GetActiveTenancies
Get active tenancies
- **Parameters**: `propertyId` (optional)
- **Returns**: List of active tenancies with tenant info

#### GET /api/SearchTenants
Search for tenants
- **Parameters**: `firstName`, `lastName`, `email`, `phoneNumber` (all optional)
- **Returns**: Matching tenants with property info

#### POST /api/CreateTenancy
Create new tenancy
- **Body**:
  ```json
  {
    "propertyId": 1,
    "leaseStartDate": "2024-01-01",
    "leaseEndDate": "2024-12-31",
    "securityDeposit": 1500.00,
    "insurancePolicyNumber": "INS123"
  }
  ```

#### POST /api/AddTenant
Add tenant to tenancy
- **Body**:
  ```json
  {
    "tenancyId": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "mobile": "604-555-1234"
  }
  ```

#### PATCH /api/UpdateTenant
Update tenant information
- **Body**:
  ```json
  {
    "tenantId": 1,
    "email": "newemail@example.com",
    "mobile": "604-555-9999"
  }
  ```

#### GET /api/GetExpiringLeases
Get leases expiring soon
- **Parameters**: `daysAhead` (default: 90)
- **Returns**: Leases expiring within specified days

### Maintenance Functions

#### GET /api/GetMaintenanceRequests
Get maintenance requests
- **Parameters**: `propertyId`, `status`, `assignedTo` (all optional)
- **Returns**: Maintenance requests matching criteria

#### POST /api/CreateMaintenance
Create maintenance request
- **Body**:
  ```json
  {
    "propertyId": 1,
    "description": "Leaking faucet in kitchen",
    "actionPlan": "Replace faucet",
    "status": "Open",
    "assignedTo": "David"
  }
  ```

#### PATCH /api/UpdateMaintenance
Update maintenance request
- **Body**:
  ```json
  {
    "maintenanceId": 1,
    "status": "Closed",
    "actionPlan": "Completed repair"
  }
  ```

#### GET /api/GetInspections
Get inspections
- **Parameters**: `propertyId`, `inspectionType`, `needInspection` (all optional)
- **Returns**: Inspection records

#### POST /api/CreateInspection
Create inspection record
- **Body**:
  ```json
  {
    "propertyId": 1,
    "inspectionType": "Annual",
    "lastInspectionDate": "2024-01-15",
    "needInspection": "No",
    "inspectionNotes": "All good"
  }
  ```

### Query Functions

#### GET /api/GetUpcomingEvents
Get all upcoming events (leases, insurances, inspections, moves)
- **Returns**: List of events with dates

#### GET /api/GetOpenIssues
Get all open maintenance and inspection issues
- **Parameters**: `propertyId` (optional)
- **Returns**: Open issues

#### GET /api/GetFinancialOverview
Get financial data for properties
- **Parameters**: `propertyId` (optional)
- **Returns**: Rent, taxes, assessments

#### GET /api/GetPropertyDashboard
Get complete property dashboard
- **Returns**: All properties with key metrics

#### GET /api/GetRentHistory
Get rent history for property
- **Parameters**: `propertyId` (required)
- **Returns**: Rent history

#### POST /api/AddRent
Add rent record
- **Body**:
  ```json
  {
    "propertyId": 1,
    "rentAmount": 2500.00,
    "effectiveDate": "2024-01-01",
    "rentYear": 2024
  }
  ```

#### PATCH /api/UpdateTaxes
Update property taxes
- **Body**:
  ```json
  {
    "propertyId": 1,
    "municipalEHT": 150.00,
    "bcSpeculationTax": 200.00,
    "federalUHT": 100.00
  }
  ```

## Example Copilot Conversations

### Example 1: Find Properties
**User**: "Show me all properties in Vancouver"

**Copilot**: Calls `GetProperties` with `city=Vancouver`

**Response**: "I found 15 properties in Vancouver:
- 123 Main St, Unit 101 - Status: Active
- 456 Oak Ave, Unit 202 - Status: Rented
..."

### Example 2: Check Upcoming Expirations
**User**: "What leases are expiring in the next 60 days?"

**Copilot**: Calls `GetExpiringLeases` with `daysAhead=60`

**Response**: "You have 3 leases expiring soon:
1. 123 Main St #101 - Expires in 45 days (March 15, 2024)
2. 789 Pine Rd #305 - Expires in 52 days (March 22, 2024)
..."

### Example 3: Create Maintenance Request
**User**: "Create a maintenance request for the leaking sink at 123 Main St Unit 101"

**Copilot**:
1. Searches property: Calls `GetProperties`
2. Creates request: Calls `CreateMaintenance` with description
3. Responds: "Maintenance request #45 created for 123 Main St #101. Issue: Leaking sink. Status: Open"

### Example 4: Update Tenant Contact
**User**: "Update the email for John Doe to john.doe@newemail.com"

**Copilot**:
1. Searches tenant: Calls `SearchTenants` with `firstName=John&lastName=Doe`
2. Updates: Calls `UpdateTenant`
3. Responds: "Email updated for John Doe (Tenant ID: 5) to john.doe@newemail.com"

### Example 5: Financial Summary
**User**: "What's the current rent for 123 Main St Unit 101?"

**Copilot**:
1. Finds property: Calls `GetPropertyById`
2. Gets rent: Calls `GetRentHistory`
3. Responds: "Current rent for 123 Main St #101: $2,500/month (effective January 1, 2024)"

## Security & Best Practices

### Authentication
- All Azure Functions use **Function-level authorization**
- Store function keys in Copilot Studio securely
- Consider upgrading to **Azure AD authentication** for production

### Data Validation
- All stored procedures validate input parameters
- Functions return structured error messages
- Null handling for optional parameters

### Monitoring
- Enable Application Insights for Azure Functions
- Monitor function execution times and errors
- Track Copilot Studio conversation analytics

## Troubleshooting

### Common Issues

**1. "SqlConnectionString not configured"**
- Ensure connection string is set in Azure Function App Settings
- Verify connection string format

**2. "Stored procedure not found"**
- Verify all SQL scripts were deployed
- Check schema name (should be `pm.`)

**3. "Function returns empty data"**
- Check database has data
- Verify query parameters
- Review function logs in Azure Portal

**4. Copilot doesn't understand request**
- Add more trigger phrases to Topics
- Improve entity extraction
- Enable Generative AI features

## Next Steps

1. **Test All Functions**: Use Postman or curl to test each endpoint
2. **Create Topics**: Build Copilot Studio topics for top 10-20 scenarios
3. **Train Users**: Provide sample queries and use cases
4. **Gather Feedback**: Have sponsor team test and provide feedback
5. **Iterate**: Add more functions based on actual usage patterns

## Support

For issues or questions:
1. Check function logs in Azure Portal
2. Review Copilot Studio conversation analytics
3. Test endpoints directly with Postman
4. Review stored procedure logic in SQL Server Management Studio

---

**Created**: January 2025
**Version**: 1.0
**Database Schema**: pm (Property Management)
