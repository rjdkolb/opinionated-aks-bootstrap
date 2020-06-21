variable "allowed_ip_addresses" {
  default = ["0.0.0.0/0"]
}

variable "location" {
  default = "southafricanorth"
}

variable "terraform_state_rg" {
  default = "terraform-state-rg"
}

variable "terraform_storage_name" {
  default = ""
}

