variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}
variable "resource_group_name" {
  default = "finopay-rg"
  
}

variable "frontend_port_name" {
    default = "myfinoFrontendPort"
}

variable "frontend_ip_configuration_name" {
    default = "myfinoAGIPConfig"
}

variable "backend_address_pool_name" {
    default = "myfinoBackendPool"
}
variable "request_routing_rule_name" {
    default = "myfinoRoutingRule"
}

variable "http_setting_name" {
    default = "myfinoHTTPsetting"
}

variable "listener_name" {
    default = "myfinoListener"
}


variable "sql_db_name" {
  type        = string
  description = "The name of the SQL Database."
  default     = "fino-DB"
}

variable public_ip_name {
  type        = string
  default     = "test-public-ip"
  description = "Name of the Public IP."
}