# Specify the Azure provider
provider "azurerm" {
  features {}  # Enable all default features for the Azure provider
}

# Define a variable for the resource group name
variable "resource_group_name" {
  default = "python-app-rg"  # Default name for the resource group
}

# Define a variable for the Azure location
variable "location" {
  default = "East Europe"  # Default Azure region
}

# Create an Azure resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name  # Use the resource group name variable
  location = var.location  # Use the location variable
}

# Create an Azure App Service Plan
resource "azurerm_app_service_plan" "main" {
  name                = "python-app-plan"  # Name of the App Service Plan
  location            = azurerm_resource_group.main.location  # Use the resource group's location
  resource_group_name = azurerm_resource_group.main.name  # Use the resource group's name
  sku {
    tier = "Free"  # Use the free pricing tier
    size = "F1"  # Use the smallest size
  }
}

# Create an Azure MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "pythonmysqlsrv"  # Name of the MySQL server
  resource_group_name    = azurerm_resource_group.main.name  # Use the resource group's name
  location               = azurerm_resource_group.main.location  # Use the resource group's location
  administrator_login    = "lgsqladmin"  # Admin username for the database
  administrator_password = "Password123!"  # Admin password for the database
  sku_name               = "B1ms"  # SKU for the MySQL server
  version                = "8.0"  # MySQL version
  storage_mb             = 32768  # Storage size in MB
  zone                   = "1"  # Availability zone
  delegated_subnet_id    = null  # No delegated subnet
  private_dns_zone_id    = null  # No private DNS zone
}

# Create a MySQL database within the server
resource "azurerm_mysql_flexible_database" "main" {
  name                = "appdb"  # Name of the database
  resource_group_name = azurerm_resource_group.main.name  # Use the resource group's name
  server_name         = azurerm_mysql_flexible_server.main.name  # Use the MySQL server's name
  charset             = "utf8"  # Character set for the database
  collation           = "utf8_unicode_ci"  # Collation for the database
}

# Create an Azure App Service
resource "azurerm_app_service" "main" {
  name                = "python-webapp-service"  # Name of the App Service
  location            = azurerm_resource_group.main.location  # Use the resource group's location
  resource_group_name = azurerm_resource_group.main.name  # Use the resource group's name
  app_service_plan_id = azurerm_app_service_plan.main.id  # Use the App Service Plan's ID

  # Define application settings (environment variables)
  app_settings = {
    "DB_HOST" = azurerm_mysql_flexible_server.main.fqdn  # Database host
    "DB_USER" = "lgsqladmin"  # Database user
    "DB_PASS" = "Password123!"  # Database password
    "DB_NAME" = azurerm_mysql_flexible_database.main.name  # Database name
  }

  # Configure site settings
  site_config {
    always_on = false  # Disable "Always On" to save resources
    linux_fx_version = "PYTHON|3.11"  # Specify the runtime stack (Python 3.11)
  }
}

# Configure source control for the App Service
resource "azurerm_app_service_source_control" "main" {
  app_id                 = azurerm_app_service.main.id  # Use the App Service's ID
  repo_url               = "https://github.com/lgreszczuk/technicalassesement/app"  # GitHub repository URL
  branch                 = "main"  # Branch to deploy from
  use_manual_integration = true  # Use manual integration for deployment
}