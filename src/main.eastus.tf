module "rg-appsvc-1" {
  source = "./modules/tfresourcegroup"
  rg_topic = "appsvc"
  rg_location = var.rg_location
}