#############
# VARIABLES #
#############

variable "location" {
}

variable "onprem_location" {
}

variable "tags" {
  type = map(string)

  default = {
    project = "Enterprise-Class-Networking"
  }
}

variable "hub_prefix" {}
variable "onprem_prefix" {}
variable "server_prefix" {}

variable "ipgroup_deny_prefix" {}


variable "sku_name" {
  default = "AZFW_VNet"
}

variable "sku_tier" {
  default = "Standard"
}

variable "active_active" {
  default = true
}


## Sensitive Variables for the Jumpbox
## Sample terraform.tfvars File

# admin_password = "ChangeMe"
# admin_username = "sysadmin"
