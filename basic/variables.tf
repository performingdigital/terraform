# module "k8s_app" in modules/kubernetes_app/main.tf
variable "namespace" {
  description = "K8s namespace to use"
}

variable "app_name" {
  description = "Name of the application"
}

variable "app_port" {
  description = "Name of the application"
}

variable "app_image" {
  description = "Image registry url of the application"
}

variable "app_ingress_annotations" {
  description = "Image registry url of the application"
  type = map(string)
}

variable "domains" {
  description = "Domains of the application"
  default     = []
}

variable "app_registry_secret" {
  description = "App image registry secret"
  default     = ""
}

variable "app_restart_policy" {
  description = "App container restart policy"
  default     = "Always"
}

variable "app_image_pull_policy" {
  description = "App image pull policy from registry"
  default     = "Always"
}

variable "app_min_replicas" {
  description = "App Min Replicas"
  default     = 0
}
variable "app_max_replicas" {
  description = "App Max Replicas"
  default     = 0
}
variable "app_cpu_utilization" {
  description = "App Cpu Utilization"
  default     = 0
}
variable "app_memory_utilization" {
  description = "App Memory Utilization"
  default     = 0
}

variable "app_probe" {
  description = ""
  default = {
    enabled : true
    path : "/"
  }
}

variable "cpu" {
  description = "CPU resources for the application"
  default     = "0.5"
}

variable "memory" {
  description = "Memory resources for the application"
  default     = "512Mi"
}
