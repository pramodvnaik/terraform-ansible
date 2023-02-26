resource "azurerm_resource_group" "demo_rg" {
  location = var.location
  name = var.resource_rg_name
}

resource "azurerm_virtual_network" "demo_vnet" {
  depends_on = [
      azurerm_resource_group.demo_rg
    ]
  name = "demo-vnet"
  address_space = [var.vnet_cidr]
  location = var.location
  resource_group_name = var.resource_rg_name

  tags = {
    "environmen" = "Dev"
  }
}

resource "azurerm_subnet" "demo_subnet1" {
  name = "Demo-Subnet-1"
  address_prefixes = [var.subnet1_cidr]
  virtual_network_name = azurerm_virtual_network.demo_vnet.name
  resource_group_name = azurerm_resource_group.demo_rg.name
  depends_on = [
    azurerm_virtual_network.demo_vnet
  ]
}

resource "azurerm_subnet" "demo_subnet2" {
  name = "Demo-Subnet-2"
  address_prefixes = [var.subnet2_cidr]
  virtual_network_name = azurerm_virtual_network.demo_vnet.name
  resource_group_name = azurerm_resource_group.demo_rg.name
   depends_on = [
    azurerm_virtual_network.demo_vnet
  ]
}   

resource "azurerm_public_ip" "demo_pip" {
  resource_group_name = azurerm_resource_group.demo_rg.name
  location = var.location
  name = "demo-pip"
  allocation_method = "Static"
  depends_on = [
    azurerm_resource_group.demo_rg
  ]
}

resource "azurerm_network_interface" "demo_public_nic" {
  name = "demo-Public-web-nic"
  location = var.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  ip_configuration {
    name = "Demo-private-ip"
    public_ip_address_id = azurerm_public_ip.demo_pip.id
    subnet_id = azurerm_subnet.demo_subnet1.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_subnet.demo_subnet1,
    azurerm_public_ip.demo_pip
  ]
}


resource "azurerm_network_interface" "private_nic" {
  name ="Demo-Terraform-db-nic"
  location = var.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  ip_configuration {
    name = "Demo-DB-privateIP"
    private_ip_address = "10.0.2.5"
    private_ip_address_allocation="Static"
    subnet_id = azurerm_subnet.demo_subnet2.id
  }

  depends_on = [
    azurerm_subnet.demo_subnet2
  ]

}

resource "azurerm_virtual_machine" "demo-frontend" {
  name = "Demo-terraform-linux"
  location = var.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  network_interface_ids = [azurerm_network_interface.demo_public_nic.id]
  vm_size = "Standard_DS1_v2"

  delete_data_disks_on_termination = true

  depends_on = [
    azurerm_network_interface.demo_public_nic
  ]

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  } 

  storage_os_disk {
    name = "demo_os_disk"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  

  os_profile {
    computer_name = "ubuntuweb"
    admin_username = var.admin_username
    admin_password = var.admin_password
  } 

  os_profile_linux_config {
    disable_password_authentication = false
  }

}

