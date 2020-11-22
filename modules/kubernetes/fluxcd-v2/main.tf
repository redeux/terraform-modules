terraform {
  required_version = "0.13.5"

  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "0.0.4"
    }
    azuredevops = {
      source  = "xenitab/azuredevops"
      version = "0.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.9.1"
    }
  }
}

locals {
  repo_url = "https://dev.azure.com/${var.azdo_org}/${var.azdo_proj}/_git/${var.repository_name}"
}

# FluxCD
data "flux_install" "main" {
  target_path = var.git_path
}

data "flux_sync" "main" {
  target_path = var.git_path
  url         = local.repo_url
}

data "flux_sync" "groups" {
  for_each = {
    for ns in var.namespaces :
    ns.name => ns
    if ns.flux.enabled
  }

  name = each.key
  target_path = var.git_path
  url         = local.repo_url
}

# Azure DevOps
data "azuredevops_project" "this" {
  name = var.azdo_proj
}

resource "azuredevops_git_repository" "this" {
  project_id = data.azuredevops_project.this.id
  name       = var.repository_name
  initialization {
    init_type = "Clean"
  }
}

resource "azuredevops_git_repository_file" "install" {
  repository_id = azuredevops_git_repository.this.id
  file       = data.flux_install.main.path
  content    = data.flux_install.main.content
  branch     = var.branch
}

resource "azuredevops_git_repository_file" "sync" {
  repository_id = azuredevops_git_repository.this.id
  file       = data.flux_sync.main.path
  content    = data.flux_sync.main.content
  branch     = var.branch
}

resource "azuredevops_git_repository_file" "kustomize" {
  repository_id = azuredevops_git_repository.this.id
  file       = data.flux_sync.main.kustomize_path
  content    = data.flux_sync.main.kustomize_content
  branch     = var.branch
}

resource "azuredevops_git_repository_file" "groups" {
  for_each = {
    for ns in var.namespaces :
    ns.name => ns
    if ns.flux.enabled
  }

  repository_id = azuredevops_git_repository.this.id
  file       = data.flux_sync.groups[each.key].path
  content    = data.flux_sync.groups[each.key].content
  branch     = var.branch
}

# Kubernetes
resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }
}

data "kubectl_file_documents" "install" {
  content = data.flux_install.main.content
}

resource "kubectl_manifest" "install" {
  for_each   = { for v in data.kubectl_file_documents.install.documents : sha1(v) => v }
  depends_on = [kubernetes_namespace.flux_system]

  yaml_body = each.value
}

data "kubectl_file_documents" "sync" {
  content = data.flux_sync.main.content
}

resource "kubectl_manifest" "sync" {
  for_each   = { for v in data.kubectl_file_documents.sync.documents : sha1(v) => v }
  depends_on = [kubectl_manifest.install, kubernetes_namespace.flux_system]

  yaml_body = each.value
}

resource "kubernetes_secret" "main" {
  depends_on = [kubectl_manifest.install]

  metadata {
    name      = data.flux_sync.main.name
    namespace = data.flux_sync.main.namespace
  }

  data = {
    username = var.azdo_org
    password = var.azdo_pat
  }
}