locals {
  tags = {
    environment = var.environment
    department = var.department
  }
}

# Resource Group
resource "azurerm_resource_group" "tfmanaged" {
  name = "rg-${var.rg_topic}-${var.rg_increment}"
  location = var.rg_location
  tags = local.tags
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

resource "azuread_application_federated_identity_credential" "deployer_spn_cred" {
    application_id = azuread_application_registration.deployer_app.id
    display_name = "${azuread_application_registration.deployer_app}-deployer-cred"
    description = "Used to deploy resources to ${azurerm_resource_group.tfmanaged.name} with Terraform."
    audiences = ["TODO"]
    issuer = "TODO"
    subject = "TODO"
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

resource "azurerm_storage_container" "tfstate_container" {
    name = "tfstate-container"
    storage_account_name = azurerm_storage_account.tfstate
    container_access_type = "private"
}