# 1. SUBREDES OBLIGATORIAS PARA AZURE FIREWALL BASIC EN EL HUB
resource "azurerm_subnet" "fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = module.redes["hub"].vnet_name
  address_prefixes     = ["10.0.2.0/26"]
}

resource "azurerm_subnet" "fw_mgmt_subnet" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = module.redes["hub"].vnet_name
  address_prefixes     = ["10.0.3.0/26"]
}

# 2. IPS PÚBLICAS (Tráfico y Administración)
resource "azurerm_public_ip" "fw_pip" {
  name                = "pip-fw-hub-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "fw_mgmt_pip" {
  name                = "pip-fw-mgmt-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 3. POLÍTICA Y REGLA DE SALIDA (Permite HTTP/HTTPS/DNS desde spoke-app)
resource "azurerm_firewall_policy" "fw_policy" {
  name                = "fwpol-hub-dev"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}

resource "azurerm_firewall_policy_rule_collection_group" "fw_rules" {
  name               = "rcg-outbound-dev"
  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  priority           = 100

  network_rule_collection {
    name     = "allow-spoke-app-outbound"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-web-and-dns"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.1.0.0/16"] # Segmento de spoke-app
      destination_addresses = ["*"]
      destination_ports     = ["80", "443", "53"]
    }
  }
}

# 4. AZURE FIREWALL (SKU BASIC)
resource "azurerm_firewall" "fw_hub" {
  name                = "fw-hub-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  firewall_policy_id  = azurerm_firewall_policy.fw_policy.id

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.fw_subnet.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }

  management_ip_configuration {
    name                 = "fw-mgmt-ipconfig"
    subnet_id            = azurerm_subnet.fw_mgmt_subnet.id
    public_ip_address_id = azurerm_public_ip.fw_mgmt_pip.id
  }
}

# 5. TABLA DE RUTAS (UDR) PARA FORZAR TRÁFICO DE SPOKE-APP AL FIREWALL
resource "azurerm_route_table" "rt_spoke_app" {
  name                = "rt-spoke-app-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw_hub.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "assoc_spoke_app" {
  subnet_id      = module.redes["spoke-app"].subnet_id
  route_table_id = azurerm_route_table.rt_spoke_app.id
}