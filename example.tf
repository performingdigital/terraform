terraform {
  backend "kubernetes" {
    secret_suffix = "state"
    config_path   = "~/.kube/config"
  }
}

# main.tf in your project-specific Terraform configuration
module "project" {
  source = "git::https://github.com/performingdigital/terraform//basic"

  namespace = "terraform-test-deploy"

  app_name  = "terraform-nginx-test-app"
  app_image = "nginx:latest"
  app_port  = 80

  app_ingress_annotations = {
    "cert-manager.io/cluster-issuer" : "letsencrypt-prod",
    "kubernetes.io/ingress.class" : "nginx",
    "nginx.ingress.kubernetes.io/proxy-body-size" : "16m"
  }

  domains = [
    "domain.example.com"
  ]

  app_probe = {
    enabled = true
    path    = "/"
  }

  cpu    = "100m"
  memory = "100Mi"

  app_min_replicas    = 2
  app_max_replicas    = 4
  app_cpu_utilization = 60
}
