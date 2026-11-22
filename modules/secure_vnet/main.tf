# 1. Creamos la VNet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.env}" # Interpolación: si env="dev", será "vnet-dev"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
}

# 2. Creamos la Subred dentro de la VNet
resource "azurerm_subnet" "dmz" {
  name                = "snet-dmz-${var.env}"
  resource_group_name = var.resource_group_name
  # DEPENDENCIA IMPLÍCITA: Al usar .vnet.name, Terraform sabe automáticamente
  # que PRIMERO debe crear la VNet y LUEGO esta subred.
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
}

# 3. Creamos el Network Security Group (Firewall básico)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-dmz-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-HTTPS-From-MyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.allowed_ip
    destination_address_prefix = "*"
  }
}

# 4. Asociamos el NSG a la Subred
# En Terraform, conectar dos recursos suele ser un recurso aparte.
resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.dmz.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}