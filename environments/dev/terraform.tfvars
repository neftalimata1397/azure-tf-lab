location = "eastus2"

redes = {
  hub = {
    vnet_name     = "vnet-hub-dev"
    address_space = ["10.0.0.0/16"]
    subnet_name   = "snet-hub-shared"
    subnet_prefix = ["10.0.1.0/24"]
    nsg_rules     = []
  }

  spoke-app = {
    vnet_name     = "vnet-spoke-app-dev"
    address_space = ["10.1.0.0/16"]
    subnet_name   = "snet-app"
    subnet_prefix = ["10.1.1.0/24"]
    nsg_rules = [
      {
        name                       = "Allow-HTTP-Web"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Allow-SSH-MyIP"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "187.189.68.140/32"
        destination_address_prefix = "*"
      }
    ]
  }

  spoke-data = {
    vnet_name     = "vnet-spoke-data-dev"
    address_space = ["10.2.0.0/16"]
    subnet_name   = "snet-data"
    subnet_prefix = ["10.2.1.0/24"]
    nsg_rules     = []
  }
}

cloudflare_zone_id = "e32ffb8b1686b6a851adba0033e189fe"
domain_name        = "sv-solution.com"
subdomain          = "tools"