#resource "kubernetes_service_account" "k8sSa" {
#  depends_on = [kubernetes_namespace.k8sSaNs]
#  for_each = { for ns in var.kuberentes_namespaces : ns.name => ns }
#
#  metadata {
#    name      = "sa-${each.value.name}"
#    namespace = local.service_account_namespace
#  }
#}
#
#data "kubernetes_secret" "k8sSaSecret" {
#  depends_on = [kubernetes_namespace.k8sSaNs]
#  for_each = { for ns in var.kuberentes_namespaces : ns.name => ns }
#
#  metadata {
#    name      = kubernetes_service_account.k8sSa[each.key].default_secret_name
#    namespace = local.service_account_namespace
#  }
#}
#
#resource "azurerm_key_vault_secret" "serviceAccountKvSecret" {
#  for_each = { for ns in var.kuberentes_namespaces : ns.name => ns }
#
#  name     = "${var.commonName}-${each.value.name}-serviceaccount-kubeconfig"
#  value = base64encode(jsonencode({
#    apiVersion = "v1"
#    kind       = "Config"
#    clusters = [
#      {
#        cluster = {
#          certificate-authority-data = base64encode(lookup(data.kubernetes_secret.k8sSaSecret[each.key].data, "ca.crt"))
#          server                     = azurerm_kubernetes_cluster.aks.kube_config.0.host
#        }
#        name = ""
#      }
#    ]
#    users = [
#      {
#        name = ""
#        user = {
#          token = data.kubernetes_secret.k8sSaSecret[each.key].data.token
#        }
#      }
#    ]
#    contexts        = null
#    current-context = ""
#  }))
#  key_vault_id = data.azurerm_key_vault.coreKv.id
#}
#
#resource "azurerm_key_vault_secret" "serviceAccountKvRgSecret" {
#  for_each = { for ns in var.kuberentes_namespaces : ns.name => ns }
#
#  name     = "${var.commonName}-${each.value.name}-serviceaccount-kubeconfig"
#  value = base64encode(jsonencode({
#    apiVersion = "v1"
#    kind       = "Config"
#    clusters = [
#      {
#        cluster = {
#          certificate-authority-data = base64encode(lookup(data.kubernetes_secret.k8sSaSecret[each.key].data, "ca.crt"))
#          server                     = azurerm_kubernetes_cluster.aks.kube_config.0.host
#        }
#        name = ""
#      }
#    ]
#    users = [
#      {
#        name = ""
#        user = {
#          token = data.kubernetes_secret.k8sSaSecret[each.key].data.token
#        }
#      }
#    ]
#    contexts        = null
#    current-context = ""
#  }))
#  key_vault_id = data.azurerm_key_vault.kvRg[each.key].id
#}
