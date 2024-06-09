module "rg-appsvc-2" {
  source = "./modules/tfresourcegroup"
  rg_topic = "appsvc"
  rg_location = var.rg_location
  rg_increment = 2
}