provider "azurerm" {
  version = "2.13.0"
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name = "terraform-state-rg"
    storage_account_name = "r3kioterraformstorage"
    container_name = "terraform-state"
    key = "dev.terraform.tfstate"
  }
}

provider "null" {
  version = "~> 2.1"
}

provider "helm" {
  version = "~> 1.2.3"
  debug = true
  kubernetes {
    config_context = var.aks_cluster_name
  }
}

resource "azurerm_resource_group" "aks-rg" {
  name = "${var.aks_cluster_name}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name = var.aks_cluster_name
  location = var.location
  resource_group_name = azurerm_resource_group.aks-rg.name
  dns_prefix = var.aks_cluster_name
  kubernetes_version = var.kubernetes_version

  node_resource_group = "${var.aks_cluster_name}-node-rg"

  api_server_authorized_ip_ranges = var.allowed_ip_addresses

  default_node_pool {
    name = "default"
    min_count = 1
    max_count = 10
    node_count = 1
    enable_auto_scaling = true
    vm_size = var.vm_size
  }
  network_profile {
    network_plugin = "azure"
    # load_balancer_sku must be standard for static ipv4 or you will the following error:
    # `kubectl -n ingress get events` -> "kubernetes cannot reference Standard sku publicIP"
    load_balancer_sku = "standard"
  }
  role_based_access_control {
    enabled = true
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "null_resource" "k8s_credentials" {
  depends_on = [
    azurerm_kubernetes_cluster.cluster]

  provisioner "local-exec" {
    command = "az aks get-credentials -g ${azurerm_resource_group.aks-rg.name} -n ${var.aks_cluster_name} --overwrite-existing"
  }
}

resource "azurerm_public_ip" "ipv4" {
  depends_on = [
    azurerm_kubernetes_cluster.cluster]
  name = "${var.aks_cluster_name}-lb01-ipv4"
  resource_group_name = "${var.aks_cluster_name}-node-rg"
  location = var.location
  sku = "Standard"
  allocation_method = "Static"
  ip_version = "IPv4"
}

resource "azurerm_dns_zone" "domain-zone" {
  depends_on = [
    azurerm_public_ip.ipv4]
  name = var.dns_zone
  resource_group_name = azurerm_resource_group.aks-rg.name
}

resource "azurerm_dns_a_record" "domain-zone-a-record" {
  name = "*.${var.aks_cluster_name}"
  zone_name = azurerm_dns_zone.domain-zone.name
  resource_group_name = azurerm_resource_group.aks-rg.name
  ttl = 300
  records = [
    azurerm_public_ip.ipv4.ip_address]
}

resource "null_resource" "helm-pull-ingress" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "helm repo add nginx-stable https://helm.nginx.com/stable || true"
  }
  provisioner "local-exec" {
    command = "helm repo update"
  }

  provisioner "local-exec" {
    command = "helm pull nginx-stable/nginx-ingress --version ${var.ingress_version} --destination ./externalcharts --untar --untardir ${var.ingress_version} || true"
  }
}

resource "helm_release" "ingress" {
  depends_on = [
    null_resource.helm-pull-ingress,
    null_resource.k8s_credentials,
    azurerm_public_ip.ipv4]
  name = "ingress"
  repository = "https://helm.nginx.com/stable"
  chart = "nginx-ingress"
  version = var.ingress_version

  create_namespace = true
  namespace = "ingress"
  cleanup_on_fail = true
  force_update = true

  set {
    name = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.ipv4.ip_address
    type = "string"
  }
}

resource "null_resource" "helm-pull-cert-manager" {
  depends_on = [null_resource.helm-pull-ingress]
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "helm repo add jetstack https://charts.jetstack.io || true"
  }
  provisioner "local-exec" {
    command = "helm repo update"
  }
  provisioner "local-exec" {
    command = "helm pull jetstack/cert-manager --version ${var.cert_manager_version} --destination ./externalcharts --untar --untardir ${var.cert_manager_version} || true"
  }

}

resource "helm_release" "helm-install-cert-manager" {
  depends_on = [
    helm_release.ingress,
    null_resource.helm-pull-cert-manager]
  name = "cert-manager"

  chart = "${path.root}/externalcharts/${var.cert_manager_version}/cert-manager"
  create_namespace = true
  namespace = "cert-manager"


  set {
    name = "installCRDs"
    value = true
  }

  set {
    name = "ingressShim.defaultIssuerName"
    value = "letsencrypt-prod"
    type = "string"
  }

  set {
    name = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
    type = "string"
  }

  set {
    name = "ingressShim.defaultIssuerGroup"
    value = "cert-manager.io"
    type = "string"
  }
}

resource "null_resource" "configure-cluster-manager-issuer" {
  depends_on = [
    helm_release.helm-install-cert-manager]

  provisioner "local-exec" {
    command = "kubectl apply --namespace=cert-manager -f ${path.root}/config/cluster-issuer.yaml"
  }
}
