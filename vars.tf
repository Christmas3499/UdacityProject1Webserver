variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "Azuredevops"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  type        = string
  default     = "South Central US"
}

variable "image_name" {
  description = "image-name"
  type        = string
  default     = "Project1Image"
}

variable "username" {
  description = "admin username"
  type        = string
  default     = "udacityVM"
}

variable "password" {
  description = "admin password"
  type        = string
  default     = "Admin1234!"
}

variable "count_vms" {
  description = "count of virtual machines"
  type        = number
  default     = 3
}
variable "subscription_id" {
  default = "17fc1a23-7619-4af8-9180-e8388fc413a3"
  type = string
}

variable "client_id" {
  default = "9a039845-e467-46e0-bc7b-40c80c3d131a"
  type = string
}

variable "client_secret" {
  default = "J8u8Q~q3pUPLs_5oou~dRjv~KuTdwJ_e4w6p4c9p"
  type = string
}

variable "tenant_id" {
  default = "f958e84a-92b8-439f-a62d-4f45996b6d07"
  type = string
}
