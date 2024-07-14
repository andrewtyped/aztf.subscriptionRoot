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
    resource_group_scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.tfmanaged.name}"
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

data "azuredevops_project" "current" {
  name = var.azure-devops-project-name
}

resource "azuredevops_serviceendpoint_azurerm" "deployer_service_connection" {
  project_id                             = data.azuredevops_project.current.id
  service_endpoint_name                  = azuread_application_registration.deployer_app.display_name
  description                            = "Managed by Terraform"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  credentials {
    serviceprincipalid = azuread_service_principal.deployer_spn.client_id
  }
  azurerm_spn_tenantid      = var.azure_tenant_id
  azurerm_subscription_id   = data.azurerm_client_config.current.subscription_id
  azurerm_subscription_name = data.azurerm_client_config.current.subscription_id
}

# Create a federated credential that can be used in an Azure DevOps Service Connection 
resource "azuread_application_federated_identity_credential" "deployer_spn_cred" {
    application_id = azuredevops_serviceendpoint_azurerm.deployer_service_connection.service_principal_id
    display_name = "${azuread_application_registration.deployer_app.display_name}-deployer-cred"
    description = "Used to deploy resources to ${azurerm_resource_group.tfmanaged.name} with Terraform."
    audiences = [var.azure-devops-oidc-token-audience]
    issuer = azuredevops_serviceendpoint_azurerm.deployer_service_connection.workload_identity_federation_issuer
    subject = azuredevops_serviceendpoint_azurerm.deployer_service_connection.workload_identity_federation_subject
}


# Grant deployer SPN access to resource group
resource "azurerm_role_assignment" "deployer_spn_rg_access" {
    principal_id = azuread_service_principal.deployer_spn.object_id
    principal_type = "ServicePrincipal"
    scope = "${local.resource_group_scope}"
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
    principal_id = data.azurerm_client_config.current.object_id
    principal_type = "ServicePrincipal"
    scope = "${local.resource_group_scope}/providers/Microsoft.Storage/storageAccounts/${azurerm_storage_account.tfstate.name}"
    role_definition_name = "Storage Blob Data Contributor"

    depends_on = [ azurerm_storage_account.tfstate ]
}

# Container for tfstate
resource "azurerm_storage_container" "tfstate_container" {
    name = "tfstate-container"
    storage_account_name = azurerm_storage_account.tfstate.name
    container_access_type = "private"

    depends_on = [ azurerm_role_assignment.current_spn_storage_account_access ]
}

# Grant deployer SPN access to storage account
resource "azurerm_role_assignment" "deployer_spn_storage_container_access" {
    principal_id = azuread_service_principal.deployer_spn.object_id
    principal_type = "ServicePrincipal"
    scope = "${local.resource_group_scope}/providers/Microsoft.Storage/storageAccounts/${azurerm_storage_account.tfstate.name}/blobServices/default/containers/${azurerm_storage_container.tfstate_container.name}"
    role_definition_name = "Storage Blob Data Contributor"

    depends_on = [ azurerm_storage_container.tfstate_container ]
}