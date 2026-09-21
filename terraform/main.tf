terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    environment = var.environment
    project     = "cicd-practice"
    created_by  = "terraform"
  }
}

# Static Web App (FREE TIER - No costs)
resource "azurerm_static_web_app" "main" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  # Free tier - no charges
  sku_tier = "Free"
  sku_size = "Free"
  
  tags = {
    environment = var.environment
    project     = "cicd-practice"
  }
}

# Output the deployment details
output "static_web_app_name" {
  value       = azurerm_static_web_app.main.name
  description = "Name of the Static Web App"
}

output "static_web_app_url" {
  value       = "https://${azurerm_static_web_app.main.default_host_name}"
  description = "URL of the deployed Static Web App"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Name of the resource group"
}

output "resource_group_id" {
  value       = azurerm_resource_group.main.id
  description = "ID of the resource group"
}
