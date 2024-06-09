provider "azurerm" {
  features {}

  # We assume that the principal used to apply is an 
  # Azure service principal using workload identity federation
  # through Azure DevOps.
  use_oidc = true

  # Instruct Terraform to use Azure AD rather than SAS keys for storage blob and queue operations
  storage_use_azuread = true
}

provider "azuread" {
  use_oidc = true
  tenant_id = var.azure_tenant_id
}

provider "azuredevops" {
  personal_access_token = var.azure_devops_pat
  org_service_url = var.azure_devops_org
}