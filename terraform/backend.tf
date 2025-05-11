terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatebackendstore"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  subscription_id = "26a031e1-ce9d-498d-84fa-064720e59855"
}