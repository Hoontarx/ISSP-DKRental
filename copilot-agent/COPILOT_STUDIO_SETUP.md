# Copilot Studio Setup Guide

## Prerequisites

1. ✅ Azure SQL Database deployed with schema
2. ✅ Stored procedures and views deployed
3. ✅ Azure Functions deployed and running
4. ✅ Function keys obtained from Azure Portal
5. ✅ Microsoft Copilot Studio access

## Step-by-Step Setup

### Step 1: Create Your Copilot Agent

1. Go to [Copilot Studio](https://copilotstudio.microsoft.com/)
2. Click **Create** → **New copilot**
3. Name it: "Property Management Assistant"
4. Choose language: English
5. Click **Create**

### Step 2: Configure Database Knowledge Source

1. In your copilot, go to **Knowledge** → **Add knowledge**
2. Select **Dataverse** or **Azure SQL** (if available)
3. Connect to your Azure SQL database
4. Select these views as knowledge sources:
   - `pm.vw_PropertyOverview`
   - `pm.vw_ActiveTenancies`
   - `pm.vw_PropertyDashboard`
   - `pm.vw_UpcomingEvents`

This allows the copilot to understand your data structure and provide better responses.

### Step 3: Create Actions

Actions connect your copilot to Azure Functions. Create these key actions:

#### Action 1: Get Property Dashboard

1. Go to **Actions** → **Add an action**
2. Select **Create from blank**
3. Configure:
   - **Name**: GetPropertyDashboard
   - **Description**: "Get a complete dashboard view of all properties with key metrics"
   - **Connection**: HTTP
   - **URL**: `https://your-function-app.azurewebsites.net/api/GetPropertyDashboard`
   - **Method**: GET
   - **Authentication**: API Key
     - Header name: `x-functions-key`
     - Key value: [Your function key from Azure Portal]

4. Click **Save**

#### Action 2: Search Properties

1. Create new action
2. Configure:
   - **Name**: SearchProperties
   - **Description**: "Search for properties by city, province, status, or unit type"
   - **URL**: `https://your-function-app.azurewebsites.net/api/GetProperties`
   - **Method**: GET
   - **Parameters**:
     - `city` (String, Optional): "City name to filter by"
     - `province` (String, Optional): "Province to filter by"
     - `status` (String, Optional): "Property status (Active, Rented, etc.)"
     - `unitType` (String, Optional): "Type of unit (Condo, Apartment, etc.)"
   - **Authentication**: API Key (same as above)

#### Action 3: Get Upcoming Events

1. Create new action
2. Configure:
   - **Name**: GetUpcomingEvents
   - **Description**: "Get all upcoming events including lease expirations, insurance renewals, inspections, and moves"
   - **URL**: `https://your-function-app.azurewebsites.net/api/GetUpcomingEvents`
   - **Method**: GET
   - **Authentication**: API Key

#### Action 4: Search Tenants

1. Create new action
2. Configure:
   - **Name**: SearchTenants
   - **Description**: "Search for tenants by name, email, or phone number"
   - **URL**: `https://your-function-app.azurewebsites.net/api/SearchTenants`
   - **Method**: GET
   - **Parameters**:
     - `firstName` (String, Optional)
     - `lastName` (String, Optional)
     - `email` (String, Optional)
     - `phoneNumber` (String, Optional)
   - **Authentication**: API Key

#### Action 5: Get Maintenance Requests

1. Create new action
2. Configure:
   - **Name**: GetMaintenanceRequests
   - **Description**: "Get maintenance requests filtered by property, status, or assignee"
   - **URL**: `https://your-function-app.azurewebsites.net/api/GetMaintenanceRequests`
   - **Method**: GET
   - **Parameters**:
     - `propertyId` (Number, Optional)
     - `status` (String, Optional): "Open, In Progress, Closed"
     - `assignedTo` (String, Optional)
   - **Authentication**: API Key

#### Action 6: Create Maintenance Request

1. Create new action
2. Configure:
   - **Name**: CreateMaintenanceRequest
   - **Description**: "Create a new maintenance request for a property"
   - **URL**: `https://your-function-app.azurewebsites.net/api/CreateMaintenance`
   - **Method**: POST
   - **Body**: JSON
   - **Body Schema**:
     ```json
     {
       "type": "object",
       "properties": {
         "propertyId": { "type": "number" },
         "description": { "type": "string" },
         "actionPlan": { "type": "string" },
         "status": { "type": "string" },
         "assignedTo": { "type": "string" }
       },
       "required": ["propertyId", "description"]
     }
     ```
   - **Authentication**: API Key

#### Action 7: Update Tenant Contact

1. Create new action
2. Configure:
   - **Name**: UpdateTenantContact
   - **Description**: "Update tenant email or phone number"
   - **URL**: `https://your-function-app.azurewebsites.net/api/UpdateTenant`
   - **Method**: PATCH
   - **Body**: JSON
   - **Body Schema**:
     ```json
     {
       "type": "object",
       "properties": {
         "tenantId": { "type": "number" },
         "email": { "type": "string" },
         "mobile": { "type": "string" }
       },
       "required": ["tenantId"]
     }
     ```
   - **Authentication**: API Key

#### Action 8: Get Financial Overview

1. Create new action
2. Configure:
   - **Name**: GetFinancialOverview
   - **Description**: "Get financial information including rent, taxes, and assessments"
   - **URL**: `https://your-function-app.azurewebsites.net/api/GetFinancialOverview`
   - **Method**: GET
   - **Parameters**:
     - `propertyId` (Number, Optional)
   - **Authentication**: API Key

### Step 4: Create Topics

Topics define conversation flows. Here are essential topics to create:

#### Topic 1: Property Search

1. Go to **Topics** → **Add a topic** → **From blank**
2. Name: "Search for Properties"
3. **Trigger phrases**:
   - "show me properties"
   - "find properties in {city}"
   - "what properties do we have"
   - "list all properties"
   - "properties in {location}"

4. **Conversation flow**:
   ```
   [User message] → [Identify entities: city, province, status]
   ↓
   [Question Node] "Would you like to filter by city, province, or status?"
   ↓
   [Action: SearchProperties with extracted parameters]
   ↓
   [Message] Display results in formatted list
   ```

5. **Response template**:
   ```
   I found {count} properties:

   {foreach property in results}
   📍 {property.building_no} {property.address}, Unit {property.unit_number}
   • City: {property.city}, {property.province}
   • Type: {property.unit_type}
   • Status: {property.status}
   ---
   {endforeach}
   ```

#### Topic 2: Upcoming Expirations

1. Create new topic
2. Name: "Check Upcoming Expirations"
3. **Trigger phrases**:
   - "what's expiring soon"
   - "show upcoming events"
   - "lease expirations"
   - "what needs my attention"
   - "upcoming deadlines"

4. **Conversation flow**:
   ```
   [User message]
   ↓
   [Action: GetUpcomingEvents]
   ↓
   [Condition: Check if results > 0]
   ├─ Yes → Display events grouped by type
   └─ No → "No upcoming events in the next 90 days"
   ```

5. **Response template**:
   ```
   Here are your upcoming events:

   🏠 LEASE EXPIRATIONS:
   {foreach event where type='Lease Expiration'}
   • {event.address} - Expires in {event.days_until} days ({event.event_date})
   {endforeach}

   📋 INSURANCE RENEWALS:
   {foreach event where type contains 'Insurance'}
   • {event.address} - {event.description} in {event.days_until} days
   {endforeach}

   🔍 INSPECTIONS:
   {foreach event where type='Inspection'}
   • {event.address} - {event.description} in {event.days_until} days
   {endforeach}
   ```

#### Topic 3: Find Tenant Information

1. Create new topic
2. Name: "Find Tenant"
3. **Trigger phrases**:
   - "find tenant {name}"
   - "who lives at {address}"
   - "tenant contact for {name}"
   - "search for tenant"

4. **Conversation flow**:
   ```
   [User message] → Extract name/address
   ↓
   [Question: if no name] "What's the tenant's name?"
   ↓
   [Action: SearchTenants]
   ↓
   [Condition: Found?]
   ├─ Yes → Display tenant details
   └─ No → "No tenant found. Would you like to try a different search?"
   ```

#### Topic 4: Create Maintenance Request

1. Create new topic
2. Name: "Create Maintenance Request"
3. **Trigger phrases**:
   - "create maintenance request"
   - "log maintenance issue"
   - "report a problem at {address}"
   - "maintenance needed"

4. **Conversation flow**:
   ```
   [User message]
   ↓
   [Question] "Which property needs maintenance? (Provide building # and unit)"
   ↓
   [Action: SearchProperties to find property ID]
   ↓
   [Question] "What's the issue?"
   ↓
   [Question] "What's the action plan?" (Optional)
   ↓
   [Action: CreateMaintenanceRequest]
   ↓
   [Message] "Maintenance request #{id} created successfully!"
   ```

#### Topic 5: Update Contact Information

1. Create new topic
2. Name: "Update Contact Information"
3. **Trigger phrases**:
   - "update tenant contact"
   - "change email for {name}"
   - "update phone number"

4. **Conversation flow**:
   ```
   [User message] → Extract name if provided
   ↓
   [Question: if no name] "Whose contact info do you want to update?"
   ↓
   [Action: SearchTenants]
   ↓
   [Question] "What would you like to update? (email/phone)"
   ↓
   [Question] "What's the new {email/phone}?"
   ↓
   [Action: UpdateTenantContact]
   ↓
   [Message] "Contact updated successfully!"
   ```

### Step 5: Enable Generative AI Features

1. Go to **Settings** → **Generative AI**
2. Enable **Generative answers**
3. Set **Content moderation** to Medium
4. Configure **Knowledge sources**:
   - Add your database views
   - Add custom instructions: "You are a property management assistant. Help users manage properties, tenants, maintenance, and financial information. Always be professional and accurate."

### Step 6: Test Your Copilot

1. Click **Test your copilot** in the top right
2. Try these test conversations:

**Test 1: Property Search**
```
You: Show me all properties in Vancouver
Copilot: [Should call SearchProperties and display results]
```

**Test 2: Upcoming Events**
```
You: What needs my attention this month?
Copilot: [Should call GetUpcomingEvents and show lease expirations, etc.]
```

**Test 3: Maintenance**
```
You: Create a maintenance request for the leaking faucet at 123 Main St Unit 101
Copilot: [Should guide through property lookup and request creation]
```

**Test 4: Tenant Search**
```
You: Find tenant John Smith
Copilot: [Should search and display tenant info]
```

### Step 7: Publish Your Copilot

1. Click **Publish** in the top right
2. Select publish channels:
   - **Microsoft Teams** (recommended for team collaboration)
   - **Web** (embed in website)
   - **Mobile app**

3. For Teams:
   - Click **Publish to Teams**
   - Follow prompts to add to your organization
   - Share with your sponsor's team

### Step 8: Train Your Users

Create a quick reference guide for your sponsor:

**Property Management Assistant - Quick Reference**

📍 **Find Properties**
- "Show me properties in [city]"
- "What properties do we have with status [status]"

📅 **Check Deadlines**
- "What's expiring soon?"
- "Show upcoming events"

👥 **Find Tenants**
- "Find tenant [name]"
- "Who lives at [address]"

🔧 **Maintenance**
- "Create maintenance request for [issue] at [address]"
- "Show open maintenance requests"

💰 **Financial Info**
- "What's the current rent for [address]"
- "Show financial overview"

✏️ **Update Info**
- "Update email for [tenant name] to [email]"
- "Update phone number for [tenant]"

## Advanced Configuration

### Custom Entities

Create entities for better understanding:

1. **Property Address**
   - Type: List
   - Values: Import from your database

2. **Property Status**
   - Type: List
   - Values: Active, Rented, Vacant, Under Maintenance

3. **Maintenance Status**
   - Type: List
   - Values: Open, In Progress, Closed

### Fallback Topics

Create a fallback topic for unhandled requests:

```
If copilot doesn't understand:
"I'm not sure how to help with that. I can help you:
• Search for properties
• Find tenant information
• Create maintenance requests
• Check upcoming deadlines
• Update contact information

What would you like to do?"
```

## Monitoring & Analytics

1. Go to **Analytics** to view:
   - Most used topics
   - User satisfaction
   - Conversation success rate
   - Common user questions

2. Use insights to:
   - Add new trigger phrases
   - Create new topics for common requests
   - Improve response templates

## Troubleshooting

**Action returns error**
- Verify function app is running
- Check function key is correct
- Test endpoint directly with Postman

**Copilot doesn't trigger action**
- Check trigger phrases match user input
- Verify action is enabled
- Review conversation flow logic

**Wrong results returned**
- Verify parameters are extracted correctly
- Check entity recognition
- Test action independently

---

**🎉 Your Copilot is ready! Have your sponsor team start testing!**
