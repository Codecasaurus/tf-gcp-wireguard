variable "billing_account" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "project_name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "wireguard_ip_range" {
  type = string
}
