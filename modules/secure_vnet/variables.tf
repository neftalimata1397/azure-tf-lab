variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde vivirá la red"
}

variable "location" {
  type        = string
  description = "Región de Azure (ej. eastus2, mexicocentral)"
}

variable "env" {
  type        = string
  description = "Nombre del ambiente (dev, qa, prod) para nombrar recursos"
}

variable "vnet_cidr" {
  type        = string
  description = "Rango IP de la VNet (ej. 10.10.0.0/16)"
}

variable "subnet_cidr" {
  type        = string
  description = "Rango IP de la Subred (ej. 10.10.1.0/24)"
}

variable "allowed_ip" {
  type        = string
  description = "Tu IP pública en formato CIDR (ej. 203.0.113.10/32)"
}
