output "vnet_id" {
  description = "ID único de la VNet creada en Azure"
  value       = azurerm_virtual_network.vnet.id
}

output "nsg_name" {
  description = "Nombre del NSG creado"
  value       = azurerm_network_security_group.nsg.name
}