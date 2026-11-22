terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # Acepta cualquier versión 4.x, pero no salta a la 5.0
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-lab"
    storage_account_name = "sttfstatelab4733"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate" 
    }

}


provider "azurerm" {
  features {}
}