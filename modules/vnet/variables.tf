## vnet and subnet variables
variable "vnet_name" {
  description = "VNet名稱"
  type        = string
}

variable "location" {
  description = "VNet所在區域"
  type        = string
}

variable "resource_group_name" {
  description = "資源群組名稱"
  type        = string
}

variable "vnet_cidr" {
  description = "VNet的CIDR範圍"
  type        = string
}

variable "subnet_name" {
  description = "Subnet名稱"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet的CIDR範圍"
  type        = string
}