terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "app" {
  metadata {
    name      = format("%s-secret", var.app_name)
    namespace = var.namespace
  }
  data = {
    ".dockerconfigjson" = jsonencode(var.app_registry_secret)
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_deployment_v1" "app" {
  
  wait_for_rollout = false

  metadata {
    namespace = var.namespace
    name      = var.app_name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }
    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }
      spec {
        restart_policy = var.app_restart_policy

        dynamic "image_pull_secrets" {
          for_each = length(var.app_registry_secret) > 0 ? [1] : []
          content {
            name = format("%s-secret", var.app_name)
          }
        }
        container {
          name              = var.app_name
          image             = var.app_image
          image_pull_policy = var.app_image_pull_policy
          resources {
            limits = {
              cpu    = var.cpu
              memory = var.memory
            }
            requests = {
              cpu    = var.cpu
              memory = var.memory
            }
          }
          dynamic "liveness_probe" {
            for_each = var.app_probe.enabled ? [1] : []
            content {
              http_get {
                path   = var.app_probe.path
                port   = var.app_port
                scheme = "HTTP"
              }
              initial_delay_seconds = 30
              period_seconds        = 10
            }
          }
          dynamic "startup_probe" {
            for_each = var.app_probe.enabled ? [1] : []
            content {
              http_get {
                path   = var.app_probe.path
                port   = var.app_port
                scheme = "HTTP"
              }
              initial_delay_seconds = 30
              period_seconds        = 10
            }
          }
        }
      }

    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    namespace = var.namespace
    name      = var.app_name
    labels = {
      app = var.app_name
    }
  }
  spec {
    session_affinity = "None"
    selector = {
      app = var.app_name
    }
    port {
      port        = 80
      target_port = var.app_port
    }
  }
}

resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = format("%s-ingress", var.app_name)
    namespace = var.namespace
    annotations = var.app_ingress_annotations
  }
  spec {
    tls {
      hosts       = var.domains
      secret_name = format("%s-tls", var.app_name)
    }

    dynamic "rule" {
      for_each = var.domains
      content {
        host = rule.value

        http {
          path {
            path = "/"
            backend {
              service {
                name = var.app_name
                port {
                  number = var.app_port
                }
              }
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  metadata {
    name      = format("%s-hpa", var.app_name)
    namespace = var.namespace
  }
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = var.app_name
    }
    min_replicas = var.app_min_replicas > 0 ? var.app_min_replicas : 1
    max_replicas = var.app_max_replicas > 0 ? var.app_max_replicas : 1
    dynamic "metric" {
      for_each = var.app_cpu_utilization > 0 ? [1] : []
      content {
        type = "Resource"
        resource {
          name = "cpu"
          target {
            type                = "Utilization"
            average_utilization = var.app_cpu_utilization
          }
        }
      }
    }
    dynamic "metric" {
      for_each = var.app_memory_utilization > 0 ? [1] : []
      content {
        type = "Resource"
        resource {
          name = "memory"
          target {
            type                = "Utilization"
            average_utilization = var.app_memory_utilization
          }
        }
      }
    }
  }
}
