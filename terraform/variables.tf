variable "resource_group_name" {
  type        = string
  default     = "cicd-practice-rg"
  description = "Name of the Azure Resource Group"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,90}$", var.resource_group_name))
    error_message = "Resource group name must be 1-90 alphanumeric characters and hyphens."
  }
}

variable "location" {
  type        = string
  default     = "East US 2"
  description = "Azure region for resources"
  
  validation {
    condition     = contains(["East US 2", "Central US", "East Asia"], var.location)
    error_message = "Location must be a supported Azure region."
  }
}

variable "app_name" {
  type        = string
  default     = "cicd-practice-app"
  description = "Name of the Static Web App (globally unique)"
  
  validation {
    condition     = can(regex("^[a-z0-9-]{1,60}$", var.app_name))
    error_message = "App name must be lowercase, 1-60 characters, alphanumeric and hyphens only."
  }
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name (dev, staging, prod)"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
