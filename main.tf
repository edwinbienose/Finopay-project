resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name = var.resource_group_name
}

#Vnet, Vms, NIC, NSG creation

resource "azurerm_virtual_network" "mytf_finopay_Vnet" {
  name                = "finopay-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_subnet" "my_finopay_subnet_1" {
  name                 = "Web-tier-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mytf_finopay_Vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_subnet" "my_database_subnet_2" {
  name                 = "Database-tier-2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mytf_finopay_Vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "mytf_web_NSG" {
  name                = "Web_tier-NSG"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_https"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "mytf_database_NSG" {
  name                = "Database_tier-NSG"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Database-1"
    priority                   =  110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic-1" {
  count               = 2
  name                = "nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic-ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.my_finopay_subnet_1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "tf_avail" {
  name                = "example-aset"
  location            =  azurerm_resource_group.rg.location
  resource_group_name =  azurerm_resource_group.rg.name

  }


resource "azurerm_windows_virtual_machine" "mytf_vm2" {

  count=2
  name                  = "Web-${count.index}"
  admin_username        = "adminuser"
  admin_password        = "P@$$w0rd1234!"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.nic-1.*.id, count.index)]
  availability_set_id   = azurerm_availability_set.tf_avail.id 
  size                  = "Standard_B2s"

os_disk {
    name                 = "myOsDisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128  
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter"
    version   = "latest"
  }
}

resource "azurerm_subnet_network_security_group_association" "NS-group" {
    subnet_id = azurerm_subnet.my_finopay_subnet_1.id
    network_security_group_id = azurerm_network_security_group.mytf_web_NSG.id

    
  } 

  resource "azurerm_network_interface" "mytf_database_nic" {
  name                = "dabase-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_database_subnet_2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "myft_data" {
  name                  = "Database-vm"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.mytf_database_nic.id]
  size                  = "Standard_D4s_v3"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb        = 256

  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter"
    version   = "latest"
  }

}


resource "azurerm_subnet_network_security_group_association" "NS-group1" {
    subnet_id = azurerm_subnet.my_database_subnet_2.id
    network_security_group_id = azurerm_network_security_group.mytf_database_NSG.id
}

#load balancer

resource "azurerm_public_ip" "my_public_ip" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_lb" "my_lb" {
  name                = "lb-fino"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.public_ip_name
    public_ip_address_id = azurerm_public_ip.my_public_ip.id
  }
}


resource "azurerm_lb_backend_address_pool" "my_lb_pool" {
  loadbalancer_id      = azurerm_lb.my_lb.id
  name                 = "Fino-pool"
}

resource "azurerm_lb_probe" "my_lb_probe" {
  loadbalancer_id     = azurerm_lb.my_lb.id
  name                = "fino-probe"
  port                = 80
}

resource "azurerm_lb_rule" "my_lb_rule" {
 
  loadbalancer_id                = azurerm_lb.my_lb.id
  name                           = "fino-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  disable_outbound_snat          = true
  frontend_ip_configuration_name = azurerm_public_ip.my_public_ip.name
  probe_id                       = azurerm_lb_probe.my_lb_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.my_lb_pool.id]
}

resource "azurerm_lb_outbound_rule" "my_lboutbound_rule" {
 
  name                    = "fino-outbound"
  loadbalancer_id         = azurerm_lb.my_lb.id
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.my_lb_pool.id

  frontend_ip_configuration {
    name = var.public_ip_name
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "my_nic_lb_pool" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.nic-1[count.index].id
  ip_configuration_name   = "nic-ipconfig-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.my_lb_pool.id
}

#application gateway

resource "azurerm_subnet" "frontend" {
  name                 = "myAGSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mytf_finopay_Vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "Web-tier-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mytf_finopay_Vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_public_ip" "pip" {
  name                = "myAGPublicIPAddress"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_application_gateway" "mytf_appgw" {
  name                = "myAppGateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = var.backend_address_pool_name
  }

  backend_http_settings {
    name                  = "http_setting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.listener_name
    backend_address_pool_name  = var.backend_address_pool_name
    backend_http_settings_name = "http_setting"
    priority                   = 1
  }
}
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.nic-1[count.index].id
  ip_configuration_name   = "nic-ipconfig-${count.index}"
  backend_address_pool_id = one(azurerm_application_gateway.mytf_appgw.backend_address_pool).id
}

#Azure SQL Database & SQL server (There is preference in location deployment)



resource "azurerm_mssql_server" "app_server" {
  name                         = "appserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Azure@123"
}

resource "azurerm_mssql_database" "app_db" {
  name               = "appdb"
  server_id          = azurerm_mssql_server.app_server.id
  sku_name           = "S0"
   
}

resource "azurerm_mssql_firewall_rule" "app_server_firewall_rule" {
  name                = "app-server-firewall-rule"
  server_id       = azurerm_mssql_server.app_server.id
  start_ip_address    = "10.0.0.1"
  end_ip_address      = "10.255.255.254"

}



#Azure backup Web tier  #This returns an error as at the time of completing this scrpit due to error status code 500 (internal server error) from Azure end. 


resource "azurerm_recovery_services_vault" "mytf_recovery" {
  name                = "fino-recovery-vault"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "vm_policy" {
  name                = "fino-recovery-vault-policy"
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.mytf_recovery.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }
  retention_daily {
    count = 10
  }
}

data "azurerm_virtual_machine" "mytf_vm2" {

  count=2
  name                = "Web-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_backup_protected_vm" "vm1" {
  count=2
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.mytf_recovery.name
  source_vm_id        = data.azurerm_virtual_machine.mytf_vm2[count.index].id
  backup_policy_id    = azurerm_backup_policy_vm.vm_policy.id
}

#Azure backup Database 
data "azurerm_virtual_machine" "mytf_data" {
  name                = "Database-vm"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_backup_protected_vm" "vm2" {
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.mytf_recovery.name
  source_vm_id        = data.azurerm_virtual_machine.mytf_data.id
  backup_policy_id    = azurerm_backup_policy_vm.vm_policy.id
}


#Azure Security center ( Microsoft Defender for cloud)

 data "azurerm_subscription" "current" {}

 resource "azurerm_subscription_policy_assignment" "fino_assignment" {
  name                 = "fino"
  display_name         = "Microsoft Cloud Security Benchmark"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8" #sample subscription
  subscription_id      = data.azurerm_subscription.current.id
}

resource "azurerm_security_center_subscription_pricing" "vm_servers" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
  
}

resource "azurerm_security_center_subscription_pricing" "dabase_servers" {
  tier          = "Standard"
  resource_type = "SqlServers"
  
}















