terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# Variables
variable "subscription_id" {
  sensitive = true
}

variable "tenant_id" {
  sensitive = true
}

variable "client_id" {
  sensitive = true
}

variable "client_secret" {
  sensitive = true
}

variable "location" {
  default = "centralus"
}

variable "vm_name" {
  type = string
}

variable "admin_username" {
  sensitive = true
}

variable "admin_password" {
  sensitive = true
}

data "azurerm_subnet" "default" {
  name                 = "default"
  virtual_network_name = "rmg-ops"
  resource_group_name  = "rmg-ops"
}

resource "azurerm_network_interface" "default" {
  name                = "${var.vm_name}-nic"
  location            = "centralus"
  resource_group_name = "rmg-ops"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                            = var.vm_name
  resource_group_name             = "rmg-ops"
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.default.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  provision_vm_agent = true

  # Custom cloud-init data
  custom_data = base64encode(<<-EOF
    #cloud-config
    runcmd:
    - <%=instance.cloudConfig.agentInstall%>
    - <%=instance.cloudConfig.finalizeServer%>
    EOF
  )
}

output "subnet_id" {
  value = data.azurerm_subnet.default.id
}
