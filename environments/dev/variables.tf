variable "location" {
  type    = string
  default = "eastus2"
}

variable "redes" {
  description = "Mapa de redes Hub y Spokes"
  type = map(object({
    vnet_name     = string
    address_space = list(string)
    subnet_name   = string
    subnet_prefix = list(string)
    nsg_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
}