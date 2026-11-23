output "app_public_ip" {
  description = "IP pública de la VM para abrir la app o apuntar Cloudflare"
  value       = azurerm_public_ip.vm_pip.ip_address
}

output "app_url" {
  value = "http://${azurerm_public_ip.vm_pip.ip_address}"
}