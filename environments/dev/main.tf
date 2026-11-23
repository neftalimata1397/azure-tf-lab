resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-lab-dev"
  location = var.location
}

# 1. DESPLIEGUE MASIVO: Crea Hub + Spoke-App + Spoke-Data en una sola pasada
module "redes" {
  source   = "../../modules/secure_vnet"
  for_each = var.redes

  rg_name       = azurerm_resource_group.rg.name
  location      = azurerm_resource_group.rg.location
  vnet_name     = each.value.vnet_name
  address_space = each.value.address_space
  subnet_name   = each.value.subnet_name
  subnet_prefix = each.value.subnet_prefix
  nsg_rules     = each.value.nsg_rules
}

# Filtramos solo los Spokes (todo lo que no sea "hub") para crear los Peerings
locals {
  spokes = { for k, v in var.redes : k => v if k != "hub" }
}

# 2. VNET PEERINGS BIDIRECCIONALES (Hub <-> cada Spoke)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = local.spokes

  name                         = "peer-hub-to-${each.key}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = module.redes["hub"].vnet_name
  remote_virtual_network_id    = module.redes[each.key].vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = local.spokes

  name                         = "peer-${each.key}-to-hub"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = module.redes[each.key].vnet_name
  remote_virtual_network_id    = module.redes["hub"].vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# 3. MÁQUINA VIRTUAL EN SPOKE-APP CON DOCKER + IT-TOOLS (cloud-init)
resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_public_ip" "vm_pip" {
  name                = "pip-vm-app-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-vm-app-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.redes["spoke-app"].subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "vm-app-dev"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # cloud-init: instala Docker y levanta la app automáticamente al prender
  custom_data = base64encode(<<-EOF
    #cloud-config
    package_update: true
    packages:
      - docker.io
    runcmd:
      - systemctl enable --now docker
      - docker run -d --name it-tools --restart always -p 80:80 corentinth/it-tools:latest
  EOF
  )
}