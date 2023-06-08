terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.9.0"
    }

  }

  backend "azurerm" {
    # resource_group_name  = ""   # Partial configuration, provided during "terraform init"
    # storage_account_name = ""   # Partial configuration, provided during "terraform init"
    # container_name       = ""   # Partial configuration, provided during "terraform init"
    key = "enterprise-class-networking"
  }

}

provider "azurerm" {
  features {}
  disable_terraform_partner_id = false
  partner_id                   = "a30e584d-e662-44ee-9f11-ae84db89a0f0"
}
