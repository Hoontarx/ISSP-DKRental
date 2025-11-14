# Custom Connector Setup Guide for Copilot Studio

This guide walks you through creating a custom connector in Copilot Studio using the provided OpenAPI specification.

## Prerequisites

- ✅ Azure Functions deployed and running
- ✅ Function key obtained from Azure Portal
- ✅ Access to Microsoft Copilot Studio
- ✅ `openapi-spec.json` file from this repository

## Step-by-Step Instructions

### Step 1: Get Your Azure Function Details

1. **Get Function App URL**:
   - Go to [Azure Portal](https://portal.azure.com)
   - Navigate to your Function App
   - Copy the URL (e.g., `https://your-function-app.azurewebsites.net`)

2. **Get Function Key**:
   - In your Function App, go to **App Keys**
   - Under **Host keys**, copy the `default` key
   - Save this for Step 4

### Step 2: Update OpenAPI Specification

1. **Open the file**: `copilot-agent/openapi-spec.json`

2. **Update the server URL** (line 12):
   ```json
   "servers": [
     {
       "url": "https://YOUR-FUNCTION-APP.azurewebsites.net/api",
       "description": "Azure Functions Production"
     }
   ]
   ```
   Replace `YOUR-FUNCTION-APP` with your actual function app name.

3. **Save the file**

### Step 3: Import to Copilot Studio

1. **Open Copilot Studio**:
   - Go to [https://copilotstudio.microsoft.com/](https://copilotstudio.microsoft.com/)
   - Sign in with your account

2. **Navigate to Custom Connectors**:
   - In the left navigation, click **Data** or **Connectors**
   - Click **+ New connector**
   - Select **Import an OpenAPI file**

3. **Upload OpenAPI File**:
   - Click **Browse** or **Upload**
   - Select your `openapi-spec.json` file
   - Click **Continue** or **Import**

4. **Review General Information**:
   - **Connector name**: Property Management API
   - **Description**: Complete property management database API
   - **Host**: Should be auto-filled from your OpenAPI file
   - Click **Next** or **Continue**

### Step 4: Configure Security

1. **Authentication Type**:
   - Select **API Key**

2. **API Key Configuration**:
   - **Parameter label**: Function Key
   - **Parameter name**: `x-functions-key` (should be auto-filled)
   - **Parameter location**: Header (should be auto-filled)

3. Click **Next** or **Continue**

### Step 5: Review and Create

1. **Review Operations**:
   - You should see all 18 operations (endpoints)
   - Verify they're categorized by tags:
     - Properties (5 operations)
     - Tenants (6 operations)
     - Maintenance (2 operations)
     - Inspections (2 operations)
     - Reports (2 operations)
     - Financial (3 operations)

2. **Click Create Connector**

### Step 6: Test the Connection

1. **Go to the Test tab**:
   - Select your newly created connector
   - Click **Test**

2. **Create a Connection**:
   - Click **+ New connection**
   - Enter your **Function Key** (from Step 1)
   - Click **Create**

3. **Test an Operation**:
   - Select an operation (e.g., `GetPropertyDashboard`)
   - Click **Test operation**
   - Verify you get a successful response

### Step 7: Use in Your Copilot

Now you can use this connector in your copilot agent!

#### Option A: Use Actions Directly

1. **In your copilot**, go to **Actions**
2. Click **+ Add an action**
3. Select **Use a connector**
4. Choose **Property Management API**
5. Select the operations you want to use
6. Click **Finish**

#### Option B: Create Topics with Actions

Create topics that call these actions. Here are some examples:

**Example Topic 1: Search Properties**

1. **Create new topic**: "Search for Properties"
2. **Trigger phrases**:
   - "show me properties"
   - "find properties in {city}"
   - "list all properties"

3. **Topic flow**:
   ```
   [Trigger]
   ↓
   [Extract variables: city, status]
   ↓
   [Call Action: GetProperties]
     - Input: city = {city variable}
     - Input: status = {status variable}
   ↓
   [Message node]
     - "I found {count(results)} properties:"
     - Display formatted results
   ```

**Example Topic 2: Get Upcoming Events**

1. **Create new topic**: "Upcoming Deadlines"
2. **Trigger phrases**:
   - "what's expiring soon"
   - "show upcoming events"
   - "what needs attention"

3. **Topic flow**:
   ```
   [Trigger]
   ↓
   [Call Action: GetUpcomingEvents]
   ↓
   [Condition: Check if results exist]
   ├─ Yes: Display events grouped by type
   └─ No: "No upcoming events in the next 90 days"
   ```

**Example Topic 3: Create Maintenance Request**

1. **Create new topic**: "Log Maintenance Issue"
2. **Trigger phrases**:
   - "create maintenance request"
   - "log maintenance issue"
   - "report problem at {address}"

3. **Topic flow**:
   ```
   [Trigger]
   ↓
   [Question: "Which property needs maintenance?"]
   ↓
   [Call Action: GetProperties to search]
   ↓
   [Question: "What's the issue?"]
   → Store in variable: description
   ↓
   [Question: "What's the action plan?"]
   → Store in variable: actionPlan
   ↓
   [Call Action: CreateMaintenance]
     - Input: propertyId = {selected property}
     - Input: description = {description}
     - Input: actionPlan = {actionPlan}
   ↓
   [Message: "Maintenance request created successfully!"]
   ```

## All Available Operations

Here's a complete list of operations available in the connector:

### Properties (5 operations)
1. **GetProperties** - Search properties by city, province, status, or unit type
2. **GetPropertyById** - Get details of a specific property
3. **CreateProperty** - Add a new property
4. **UpdateProperty** - Update property information
5. **GetPropertyDashboard** - Get comprehensive dashboard of all properties

### Tenants (6 operations)
6. **GetActiveTenancies** - Get all active leases
7. **SearchTenants** - Search tenants by name, email, or phone
8. **CreateTenancy** - Create a new lease
9. **AddTenant** - Add a tenant to a lease
10. **UpdateTenant** - Update tenant contact info
11. **GetExpiringLeases** - Get leases expiring soon

### Maintenance (2 operations)
12. **GetMaintenanceRequests** - Get maintenance requests with filters
13. **CreateMaintenance** - Create a new maintenance request
14. **UpdateMaintenance** - Update maintenance request status

### Inspections (2 operations)
15. **GetInspections** - Get inspection records
16. **CreateInspection** - Log a new inspection

### Reports (2 operations)
17. **GetUpcomingEvents** - Get all upcoming deadlines (leases, insurance, inspections)
18. **GetOpenIssues** - Get all open maintenance and inspection issues

### Financial (3 operations)
19. **GetFinancialOverview** - Get rent, taxes, and assessments
20. **GetRentHistory** - Get rent history for a property
21. **AddRent** - Add a new rent record
22. **UpdateTaxes** - Update property tax amounts

## Natural Language Examples

Once configured, your users can interact like this:

**Property Management**
- "Show me all properties in Vancouver"
- "What's the status of property 123 Main St Unit 101?"
- "Create a new property at 456 Oak Ave"

**Tenant Management**
- "Find tenant John Smith"
- "Who lives at 123 Main St Unit 101?"
- "Update email for tenant ID 5"
- "What leases are expiring in the next 30 days?"

**Maintenance**
- "Show all open maintenance requests"
- "Create a maintenance request for leaking faucet at property 123"
- "What maintenance is assigned to David?"

**Financial**
- "What's the current rent for property 5?"
- "Show me the financial overview"
- "Update taxes for property 10"

**Reports & Alerts**
- "What needs my attention this week?"
- "Show upcoming events"
- "What inspections are overdue?"

## Troubleshooting

### Issue: "Connection failed" when testing

**Solution**:
1. Verify your Function App is running (check Azure Portal)
2. Confirm the Function Key is correct
3. Check the URL in the OpenAPI file matches your Function App URL
4. Test the endpoint directly with Postman first

### Issue: "Operation not found" error

**Solution**:
1. Verify the Azure Function was deployed successfully
2. Check that the function names in your code match the OpenAPI spec
3. Try redeploying the Azure Functions

### Issue: "Authentication failed"

**Solution**:
1. Regenerate the Function Key in Azure Portal
2. Update the connection in Copilot Studio with the new key
3. Verify the header name is `x-functions-key`

### Issue: Topics not triggering actions

**Solution**:
1. Ensure the action is added to your copilot
2. Check that variable names match between topic and action
3. Verify required parameters are being passed
4. Test the action independently first

### Issue: Empty or null responses

**Solution**:
1. Check that your database has data
2. Verify stored procedures are deployed
3. Test the stored procedure directly in SQL Server Management Studio
4. Check Azure Function logs for errors

## Advanced Configuration

### Adding Custom Descriptions

You can enhance the connector by adding more detailed descriptions:

1. **In Copilot Studio**, go to your connector
2. Click **Edit**
3. For each operation, add:
   - **Summary**: Short description (shown in action picker)
   - **Description**: Detailed explanation (shown in help text)
   - **Parameter descriptions**: Help text for each input

### Optimizing for Generative AI

To improve natural language understanding:

1. **Use clear operation names**: Match natural language (e.g., "SearchTenants" vs "GetTenantList")
2. **Add example values**: Provide sample inputs in descriptions
3. **Use consistent naming**: Keep parameter names consistent across operations
4. **Add validation**: Use enums for status fields, patterns for dates

### Performance Tips

1. **Cache common queries**: Use GetPropertyDashboard for overview, then drill down
2. **Batch operations**: Group related updates together
3. **Filter early**: Always use available filters to reduce data returned
4. **Test with real data**: Ensure responses are fast with production data volumes

## Security Best Practices

1. **Rotate Function Keys regularly**: Update in Azure and Copilot Studio
2. **Use separate keys**: Don't share keys between environments (dev/prod)
3. **Monitor usage**: Check Azure Application Insights for unusual activity
4. **Restrict access**: Limit who can create/edit connectors
5. **Use Azure AD**: Consider upgrading to Azure AD authentication for production

## Next Steps

After setting up the connector:

1. ✅ Test all operations manually
2. ✅ Create 3-5 core topics for most common tasks
3. ✅ Train your sponsor team with example queries
4. ✅ Gather feedback on response times
5. ✅ Monitor usage analytics
6. ✅ Iterate based on actual user patterns

---

**Need help?** Check the main README.md or reach out to your development team.
