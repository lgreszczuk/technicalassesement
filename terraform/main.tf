variable "resource_group_name" {
  default = "python-app-rg"
}

variable "location" {
  default = "Poland Central"
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "python-app-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet for MySQL
resource "azurerm_subnet" "mysql" {
  name                 = "mysql-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "mysql-delegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Subnet for App Service Integration
resource "azurerm_subnet" "app_service" {
  name                 = "appservice-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "mysql-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = azurerm_resource_group.main.name
}

# MySQL Flexible Server (Premium SKU)
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "pythonmysqlsrv"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  administrator_login    = "lgsqladmin"
  administrator_password = "Password123!"
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.mysql.id
  private_dns_zone_id    = azurerm_private_dns_zone.main.id
  sku_name               = "B_Standard_B1ms" # Minimum Premium tier

  depends_on = [azurerm_private_dns_zone_virtual_network_link.main]
}

resource "azurerm_mysql_flexible_database" "main" {
  name                = "appdb"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# App Service Plan (Premium V3 required for VNet Integration)
resource "azurerm_service_plan" "main" {
  name                = "python-app-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "P0v3" # Premium V3 tier
  os_type             = "Linux"
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = "python-webapp-service"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = true
    application_stack {
      python_version = "3.10"
    }
  }

  app_settings = {
    "DB_HOST" = azurerm_mysql_flexible_server.main.fqdn
    "DB_USER" = "lgsqladmin"
    "DB_PASS" = "Password123!"
    "DB_NAME" = azurerm_mysql_flexible_database.main.name
  }
}

# Enable VNet Integration for the Web App
resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_linux_web_app.main.id
  subnet_id      = azurerm_subnet.app_service.id
}
