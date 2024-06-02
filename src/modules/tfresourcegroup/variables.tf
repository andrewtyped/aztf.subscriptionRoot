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