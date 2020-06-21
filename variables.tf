variable "aks_cluster_name" {
  default = "dev-cluster"
}

variable "allowed_ip_addresses" {
  default = ["0.0.0.0/0"]
}

variable "cert_manager_version" {
  default = "v0.15.1"
}

variable "dns_zone" {
  default = "example.com"
}

variable "ingress_version" {
  default = "0.5.0"
}

variable "kubernetes_version" {
  default = "1.16.9"
}

variable "location" {
  default = "southafricanorth"
}

variable "vm_size" {
  default = "Standard_D1_v2"
}
