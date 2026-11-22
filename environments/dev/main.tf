# Creacion del grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-lab-dev"
  location = var.location
}


module "red_principal" {
  source = "../../modules/secure_vnet" # Ruta relativa hacia el módulo

  # Le pasamos los argumentos que nos pidió en modules/secure_vnet/variables.tf
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  env                 = "dev"
  vnet_cidr           = "10.10.0.0/16"
  subnet_cidr         = "10.10.1.0/24"
  allowed_ip          = var.my_ip
}

# Imprimimos en consola lo que nos devolvió el módulo
output "resultado_nsg" {
  value = module.red_principal.nsg_name
}