# Create namespaces
resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "kubernetes_namespace" "reloader" {
  metadata {
    name = "reloader"
  }
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.kubernetes_namespace
  }
}

# Service Account for External Secrets
resource "kubernetes_service_account" "external_secrets" {
  metadata {
    name      = "external-secrets-sa"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = data.terraform_remote_state.eks.outputs.external_secrets_role_arn
    }
  }
}

# Create ClusterSecretStore using kubectl_manifest which handles CRD dependencies better
resource "kubectl_manifest" "cluster_secret_store" {
  depends_on = [helm_release.external_secrets]
  
  yaml_body = <<-EOF
    apiVersion: external-secrets.io/v1beta1
    kind: ClusterSecretStore
    metadata:
      name: ${var.project_name}-store
    spec:
      provider:
        aws:
          service: ParameterStore
          region: ${var.aws_region}
          auth:
            jwt:
              serviceAccountRef:
                name: ${kubernetes_service_account.external_secrets.metadata[0].name}
                namespace: ${kubernetes_service_account.external_secrets.metadata[0].namespace}
  EOF
  
  # Retry if CRD not ready
  timeouts {
    create = "5m"
  }
}

resource "kubectl_manifest" "external_secret" {
  depends_on = [kubectl_manifest.cluster_secret_store]
  
  yaml_body = <<-EOF
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: ${var.external_secret_name}
      namespace: ${var.kubernetes_namespace}
    spec:
      refreshInterval: 5m
      secretStoreRef:
        name: ${var.project_name}-store
        kind: ClusterSecretStore
      target:
        name: ${var.kubernetes_secret_name}
      data:
      - secretKey: username
        remoteRef:
          key: /myapp/rds-username
      - secretKey: password
        remoteRef:
          key: /myapp/rds-password
      - secretKey: host
        remoteRef:
          key: /myapp/rds-host
  EOF
  
  timeouts {
    create = "2m"
  }
}

# Example application with Reloader annotation
resource "kubernetes_deployment" "example_app" {
  depends_on = [kubectl_manifest.external_secret, helm_release.reloader]

  metadata {
    name      = "example-app"
    namespace = var.kubernetes_namespace
    labels = {
      app = "example-app"
    }
    annotations = {
      "reloader.stakater.com/auto" = "true"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "example-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "example-app"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "example-app"

          env {
            name = "DB_HOST"
            value_from {
              secret_key_ref {
                name = var.kubernetes_secret_name
                key  = "host"
              }
            }
          }

          env {
            name = "DB_USERNAME"
            value_from {
              secret_key_ref {
                name = var.kubernetes_secret_name
                key  = "username"
              }
            }
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.kubernetes_secret_name
                key  = "password"
              }
            }
          }
        }
      }
    }
  }
}