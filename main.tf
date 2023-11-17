resource "azurerm_resource_group" "aks" {
  name     = "infinitypp-aks"
  location = "uksouth"
}

resource "random_id" "prefix" {
  byte_length = 8
}

module "aks" {
  source                               = "registry.terraform.io/Azure/aks/azurerm"
  version                              = "7.5.0"
  resource_group_name                  = azurerm_resource_group.aks.name
  vnet_subnet_id                       = azurerm_subnet.pods.id
  public_network_access_enabled        = true
  log_analytics_workspace_enabled      = false
  location                             = azurerm_resource_group.aks.location
  rbac_aad                             = false
  cluster_name                         = "infinitypp"
  cluster_log_analytics_workspace_name = "infinitypp"
  node_pools                           = local.nodes
  sku_tier                             = "Free"
  prefix                               = "infi-${random_id.prefix.hex}"
  depends_on = [
    azurerm_resource_group.aks
  ]
}

locals {
  nodes = {
    for i in range(1) : "worker${i}" => {
      name                  = substr("worker${i}${random_id.prefix.hex}", 0, 8)
      vm_size               = "Standard_D2s_v3"
      node_count            = 1
      vnet_subnet_id        = azurerm_subnet.pods.id
      enable_node_public_ip = true # this is should be turned off
    }
  }
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.52.0.0/16"]
  location            = azurerm_resource_group.aks.location
  name                = "${random_id.prefix.hex}-vn"
  resource_group_name = azurerm_resource_group.aks.name
  depends_on = [
    azurerm_resource_group.aks
  ]
}

resource "azurerm_subnet" "pods" {
  address_prefixes                               = ["10.52.0.0/24"]
  name                                           = "${random_id.prefix.hex}-sn"
  resource_group_name                            = azurerm_resource_group.aks.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  enforce_private_link_endpoint_network_policies = true
  depends_on = [
    azurerm_resource_group.aks
  ]
}

provider "azurerm" {
  features {}
}
