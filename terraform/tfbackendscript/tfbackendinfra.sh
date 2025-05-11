#!/bin/bash

# Variables
RESOURCE_GROUP="tfstate-rg"
LOCATION="Poland Central"
STORAGE_ACCOUNT="tfstatebackendstore"
CONTAINER_NAME="tfstate"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location "$LOCATION"

# Create storage account (must be globally unique)
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query "[0].value" -o tsv)

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY
