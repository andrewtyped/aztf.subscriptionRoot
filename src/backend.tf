terraform {
  # Sensitive backend configuration will be provided as file or environment variables. See https://developer.hashicorp.com/terraform/language/settings/backends/configuration#file
  backend "azurerm" {
    storage_account_name = "sargroot1tf"
    container_name       = "tfstate-container"
    key                  = "terraform.tfstate"
    #use_oidc signals we will use an SPN with Workload Identity Federation
    use_oidc             = true
    #use_azuread_auth signals the storage account uses Azure AD for authentication rather than an access key
    use_azuread_auth     = true
  }
}