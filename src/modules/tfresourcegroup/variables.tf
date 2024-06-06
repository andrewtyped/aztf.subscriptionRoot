# Common

variable "environment" {
    description = "The name of the environment (dev, qa, prod) where the resource is deployed"
    type = "string"
    default = "dev"
}

variable "department" {
    description = "The name of the business dept owning the resource"
    type = "string"
    default = "someco"
}

# Resource Group

variable "rg_topic" {
  description = "A description of the resource group's purpose that will be embedded into the group's name. The group will automatically be prefixed with rg-"
  type = string
}

variable "rg_increment" {
    description = "A number used to disambiguate resource groups in the same topic"
    type = number
    default = 1
}

variable "rg_location" {
    description = "The azure region where the group will be deployed"
    type = string
    default = "East US"
}

# Storage Account

variable "sa_tfstate_account_tier" {
    description = "Standard or Premium."
    type = string
    default = "Standard"
}

variable "sa_tfstate_account_replication_type" {
    description = "Valid options are LRS, GRS, RAGRS, ZRS, GZRS, and RAGZRS. "
    type = string
    default = "LRS"
}

variable "sa_tfstate_public_network_access_enabled" {
    description = "Is public network access enabled?"
    type = bool
    default = true
}