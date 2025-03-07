# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.21.0"
    }
  }
}


# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create first rg
resource "azurerm_resource_group" "rg-tf" {
  name     = "rg-pei-tf001"
  location = "East Asia"

  tags = {
    Tool = "Terraform"
  }
}


# Create storage account for backend
resource "azurerm_storage_account" "st-backend" {
  name                            = "stpeistatetf001"
  resource_group_name             = "rg-peilab"
  location                        = "East Asia"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  tags = {
    Tool = "Terraform"
  }
}

# Create blob container for backend
resource "azurerm_storage_container" "st-backend-blob" {
  name                  = "stcpeistatetf001"
  storage_account_id    = azurerm_storage_account.st-backend.id
  container_access_type = "private"
}

# Remote backend for terraform tf.state
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-peilab"
    storage_account_name = "stpeistatetf001"
    container_name       = "stcpeistatetf001"
    key                  = "terraform.tfstate" # state.tf

  }
}

# Use Vnet and subnet modules
module "vnet" {
  source              = "./modules/vnet"
  vnet_name           = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  vnet_cidr           = var.vnet_cidr
  subnet_name         = var.subnet_name
  subnet_cidr         = var.subnet_cidr
}

# Use module output
resource "azurerm_network_interface" "nic-module" {
  name                = "nic-pei-module"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "ipconfig-module"
    subnet_id                     = module.vnet.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}


data "azurerm_key_vault" "kv-vm" {
  name                = "akv-pei-tf-001" 
  resource_group_name = "rg-peilab"
}


data "azurerm_key_vault_secret" "vm-admin-username" {
  name         = "vm-admin-username" 
  key_vault_id = data.azurerm_key_vault.kv-vm.id
}

data "azurerm_key_vault_secret" "vm-admin-password" {
  name         = "vm-admin-password"
  key_vault_id = data.azurerm_key_vault.kv-vm.id
}


# Create VM
resource "azurerm_windows_virtual_machine" "vm-tf" {
  name                = "vm-pei-tf001"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B1ls"
  admin_username      = data.azurerm_key_vault_secret.vm-admin-username.value
  admin_password      = data.azurerm_key_vault_secret.vm-admin-password.value
  network_interface_ids = [
    azurerm_network_interface.nic-module.id,
  ]

  os_disk {
    name                 = "disk01-vm-pei-tf001"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-pro"
    version   = "latest"
  }

  tags = {
    Tool = "Terraform"
  }
}

