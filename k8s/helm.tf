# Install External Secrets Operator
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name
  version    = "0.9.13"
  wait       = true
  timeout    = 600

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external_secrets.metadata[0].name
  }

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [kubernetes_service_account.external_secrets]
}

# Wait for CRDs to be installed
resource "null_resource" "wait_for_crds" {
  provisioner "local-exec" {
    command = <<EOF
      echo "Waiting for external-secrets CRDs to be installed..."
      kubectl wait --for condition=established --timeout=300s crd/clustersecretstores.external-secrets.io || echo "CRD wait timed out or failed"
      kubectl wait --for condition=established --timeout=300s crd/externalsecrets.external-secrets.io || echo "ExternalSecret CRD wait timed out or failed"
      echo "CRD installation check completed"
    EOF
  }
  depends_on = [helm_release.external_secrets]
}

# Install Stakater Reloader
resource "helm_release" "reloader" {
  name       = "reloader"
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  namespace  = kubernetes_namespace.reloader.metadata[0].name
  version    = "1.0.69"
  wait       = true
  timeout    = 300

  set {
    name  = "reloader.watchGlobally"
    value = "true"
  }

  depends_on = [
    helm_release.external_secrets,
    null_resource.wait_for_crds
  ]
}