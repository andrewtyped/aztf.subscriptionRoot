locals {
  tags = {
    environment = var.environment
    department = var.department
  }
}

data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "tfmanaged" {
  name = "rg-${var.rg_topic}-${var.rg_increment}"
  location = var.rg_location
  tags = local.tags
}

locals {
    resource_group_scope = "/subscriptions/${azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.tfmanaged.name}"
}

# Service Principal for Accessing tfstate
resource "azuread_application_registration" "deployer_app" {
    display_name = "${azurerm_resource_group.tfmanaged.name}-deployer"
    description = "Used to deploy resources to ${azurerm_resource_group.tfmanaged.name} with Terraform."
    sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "deployer_spn" {
    client_id = azuread_application_registration.deployer_app.client_id
    app_role_assignment_required = false
}

# resource "azuread_application_federated_identity_credential" "deployer_spn_cred" {
#     application_id = azuread_application_registration.deployer_app.id
#     display_name = "${azuread_application_registration.deployer_app}-deployer-cred"
#     description = "Used to deploy resources to ${azurerm_resource_group.tfmanaged.name} with Terraform."
#     audiences = ["TODO"]
#     issuer = "TODO"
#     subject = "TODO"
# }

# Grant deployer SPN access to resource group
resource "azurerm_role_assignment" "deployer_spn_rg_access" {
    principal_id = azuread_service_principal.deployer_spn.object_id
    principal_type = "ServicePrincipal"
    scope = "${locals.resource_group_scope}"
    role_definition_name = "Contributor"
    skip_service_principal_aad_check = true
}

# Storage Account for tfstate
resource "azurerm_storage_account" "tfstate" {
    name = "sa${var.rg_topic}tf${var.rg_increment}"
    resource_group_name = azurerm_resource_group.tfmanaged.name
    location = azurerm_resource_group.tfmanaged.location
    account_tier = var.sa_tfstate_account_tier
    account_replication_type = var.sa_tfstate_account_replication_type
    account_kind = "StorageV2"
    access_tier = "Hot"
    # Network
    public_network_access_enabled = var.sa_tfstate_public_network_access_enabled
    enable_https_traffic_only = true
    min_tls_version = "TLS1_2"

    network_rules {
      # Needs improvement, but no networks defined yet to play around with this
      default_action = "Allow"
    }

    #Authorization
    shared_access_key_enabled = false
    default_to_oauth_authentication = true

    
    timeouts {
      #Retain defaults
      create = "60m"
      update = "60m"
      read = "5m"
      delete = "60m"
    }
}

# Grant current SPN access to storage account so it can create a container
resource "azurerm_role_assignment" "current_spn_storage_account_access" {
    principal_id = azuread_service_principal.deployer_spn.object_id
    principal_type = "ServicePrincipal"
    scope = "${locals.resource_group_scope}/providers/Microsoft.Storage/storageAccounts/${azurerm_storage_container.tfstate_container.name}"
    role_definition_name = "Storage Blob Data Contributor"
}

# Container for tfstate
resource "azurerm_storage_container" "tfstate_container" {
    name = "tfstate-container"
    storage_account_name = azurerm_storage_account.tfstate
    container_access_type = "private"
}

# Grant deployer SPN access to storage account
resource "azurerm_role_assignment" "deployer_spn_storage_container_access" {
    principal_id = azuread_service_principal.deployer_spn.object_id
    principal_type = "ServicePrincipal"
    scope = "${locals.resource_group_scope}/providers/Microsoft.Storage/storageAccounts/${azurerm_storage_container.tfstate_container.name}/blobServices/default/containers/${azurerm_storage_container.tfstate_container.name}"
    role_definition_name = "Storage Blob Data Contributor"
}