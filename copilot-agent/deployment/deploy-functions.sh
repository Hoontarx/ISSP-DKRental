#!/bin/bash

# ==============================================================
# Azure Functions Deployment Script
# ==============================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-pm-copilot-rg}"
LOCATION="${LOCATION:-westus2}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-pmcopilotstorage}"
FUNCTION_APP_NAME="${FUNCTION_APP_NAME:-pm-copilot-functions}"
SQL_CONNECTION_STRING="${SQL_CONNECTION_STRING}"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Azure Functions Deployment Script${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in to Azure
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Please login...${NC}"
    az login
fi

echo -e "${GREEN}✓ Logged in to Azure${NC}"
echo ""

# Get SQL connection string if not set
if [ -z "$SQL_CONNECTION_STRING" ]; then
    echo -e "${YELLOW}SQL Connection String not set.${NC}"
    echo "Please enter your Azure SQL connection string:"
    read -r SQL_CONNECTION_STRING
fi

# Create resource group if it doesn't exist
echo -e "${YELLOW}Creating resource group: $RESOURCE_GROUP${NC}"
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none

echo -e "${GREEN}✓ Resource group created/verified${NC}"
echo ""

# Create storage account if it doesn't exist
echo -e "${YELLOW}Creating storage account: $STORAGE_ACCOUNT${NC}"
az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --location "$LOCATION" \
    --resource-group "$RESOURCE_GROUP" \
    --sku Standard_LRS \
    --output none \
    2>/dev/null || echo "Storage account already exists"

echo -e "${GREEN}✓ Storage account created/verified${NC}"
echo ""

# Create function app if it doesn't exist
echo -e "${YELLOW}Creating Function App: $FUNCTION_APP_NAME${NC}"
az functionapp create \
    --resource-group "$RESOURCE_GROUP" \
    --consumption-plan-location "$LOCATION" \
    --runtime dotnet-isolated \
    --functions-version 4 \
    --name "$FUNCTION_APP_NAME" \
    --storage-account "$STORAGE_ACCOUNT" \
    --output none \
    2>/dev/null || echo "Function App already exists"

echo -e "${GREEN}✓ Function App created/verified${NC}"
echo ""

# Configure application settings
echo -e "${YELLOW}Configuring application settings...${NC}"
az functionapp config appsettings set \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings "SqlConnectionString=$SQL_CONNECTION_STRING" \
    --output none

echo -e "${GREEN}✓ Application settings configured${NC}"
echo ""

# Build and publish
echo -e "${YELLOW}Building Azure Functions project...${NC}"
cd ../azure-functions
dotnet build --configuration Release

echo -e "${GREEN}✓ Build completed${NC}"
echo ""

echo -e "${YELLOW}Publishing to Azure...${NC}"
func azure functionapp publish "$FUNCTION_APP_NAME" --dotnet-isolated

echo -e "${GREEN}✓ Functions published successfully${NC}"
echo ""

# Get function app URL
FUNCTION_URL=$(az functionapp show \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query defaultHostName \
    --output tsv)

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "Function App URL: ${GREEN}https://$FUNCTION_URL${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Get function keys from Azure Portal"
echo "2. Configure Copilot Studio Actions with the following base URL:"
echo "   https://$FUNCTION_URL/api/"
echo "3. Test endpoints with Postman or curl"
echo "4. Create Copilot Studio Topics"
echo ""
echo -e "${YELLOW}Example Test:${NC}"
echo "curl \"https://$FUNCTION_URL/api/GetPropertyDashboard?code=YOUR_FUNCTION_KEY\""
echo ""
