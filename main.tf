# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.17.0"
    }
  }
}

provider "azurerm" {

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  features {}
}

data "azurerm_resource_group" "Rg" {
  name                = var.resource_group_name
}

data "azurerm_image" "Image" {
 name               = var.image_name
resource_group_name = data.azurerm_resource_group.Rg.name
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group_name}-network"
  address_space       = ["10.0.0.0/22"]
  location            = data.azurerm_resource_group.Rg.location
  resource_group_name = data.azurerm_resource_group.Rg.name

  tags = {environment = "udacity" }
}

resource "azurerm_subnet" "main" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = data.azurerm_resource_group.Rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

}

resource "azurerm_public_ip" "main" {
  name                = "${var.resource_group_name}-PublicIp"
  resource_group_name = data.azurerm_resource_group.Rg.name
  location            = data.azurerm_resource_group.Rg.location
  allocation_method   = "Static"

  tags = { environment = "udacity" }
}

resource "azurerm_network_interface" "main" {
  count               = var.count_vms
  name                = "${var.resource_group_name}-${count.index}-nic"
  resource_group_name = data.azurerm_resource_group.Rg.name
  location            = data.azurerm_resource_group.Rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = { environment = "udacity" }
}

resource "azurerm_network_security_group" "main" {
  name                 = "${var.resource_group_name}-netwrk_security_group"
  location             = data.azurerm_resource_group.Rg.location
  resource_group_name  = data.azurerm_resource_group.Rg.name
  tags = { environment = "udacity" }
}

resource "azurerm_network_security_rule" "rule1" {
  name                        = "denyInboundToVMs"
  description                 = "This rule deny the inbound traffic from internet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "Internet"
  resource_group_name         = data.azurerm_resource_group.Rg.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "rule2" {
  name                        = "allowInboundToVms"
  description                 = "This rule allow the inbound traffic from other vms"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.Rg.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "rule3" {
  name                        = "allowOutboundToVms"
  description                 = "This rule allow the outbound traffic to other vms"
  priority                    = 102
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.Rg.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "rule4" {
  name                        = "allowInboundLB"
  description                 = "This rule deny the inbound traffic from internet"
  priority                    = 104
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = data.azurerm_resource_group.Rg.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_lb" "main" {
  name                = "${var.resource_group_name}-lb"
  location            = data.azurerm_resource_group.Rg.location
  resource_group_name = data.azurerm_resource_group.Rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
  tags = { environment   = "udacity" }
}

resource "azurerm_lb_backend_address_pool" "main" {

  loadbalancer_id = azurerm_lb.main.id
  name            = "${var.resource_group_name}-lb-backend-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.count_vms
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_availability_set" "main" {
  name                            = "${var.resource_group_name}-aset"  
  resource_group_name             = data.azurerm_resource_group.Rg.name
  location                        = data.azurerm_resource_group.Rg.location
  tags = { environment = "udacity" }
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.count_vms
  name                            = "${var.resource_group_name}-${count.index}-vm"
  resource_group_name             = data.azurerm_resource_group.Rg.name
  location                        = data.azurerm_resource_group.Rg.location
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [
    element(azurerm_network_interface.main.*.id,count.index)
  ]
  tags = { environment = "udacity" }
  availability_set_id             = azurerm_availability_set.main.id
  source_image_id = data.azurerm_image.Image.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}