# Obtiene el Tenant ID actual de tu sesión OIDC en Azure
data "azurerm_client_config" "current" {}

# 1. KEY VAULT CERRADO A INTERNET
resource "azurerm_key_vault" "kv_lab" {
  name                          = "kv-tflab-dev-4733" # Nombre único global (usa tus dígitos)
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true  # Estándar moderno: permisos por RBAC en lugar de Access Policies
  public_network_access_enabled = false # Bloquea el acceso público desde internet
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false # En lab va en false para poder destruir con terraform destroy
}

# 2. ZONA DNS PRIVADA (Para que la VM resuelva el Key Vault a su IP privada, no a una pública)
resource "azurerm_private_dns_zone" "kv_dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Conecta la Zona DNS Privada a TODAS tus VNets (Hub, spoke-app y spoke-data) usando for_each
resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_links" {
  for_each              = module.redes
  name                  = "link-kv-${each.key}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns.name
  virtual_network_id    = each.value.vnet_id
}

# 3. PRIVATE ENDPOINT DENTRO DE SPOKE-DATA
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-kv-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.redes["spoke-data"].subnet_id

  private_service_connection {
    name                           = "psc-kv-dev"
    private_connection_resource_id = azurerm_key_vault.kv_lab.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_dns.id]
  }
}