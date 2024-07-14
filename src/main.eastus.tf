module "rg-primary-vnet" {
  source = "./modules/tfresourcegroup"
  rg_topic = "primaryvnet"
  rg_location = var.rg_location
  rg_increment = 1
  azure-devops-project-name = var.azure-devops-project-name
  azure_tenant_id = var.azure_tenant_id
}

module "rg-appsvc-2" {
  source = "./modules/tfresourcegroup"
  rg_topic = "appsvc"
  rg_location = var.rg_location
  rg_increment = 2
  azure-devops-project-name = var.azure-devops-project-name
  azure_tenant_id = var.azure_tenant_id
}