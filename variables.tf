variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "rds-rotation"
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
  default     = "myapp-database"
}

variable "rds_master_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "rds_database_name" {
  description = "RDS database name"
  type        = string
  default     = "myapp"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.35"
}

variable "rotation_schedule" {
  description = "EventBridge schedule for rotation"
  type        = string
  default     = "cron(0 12 L * ? *)" # Month end 12 PM
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for apps"
  type        = string
  default     = "applications"
}

variable "external_secret_name" {
  description = "ExternalSecret name"
  type        = string
  default     = "rds-credentials"
}

variable "kubernetes_secret_name" {
  description = "Kubernetes secret name"
  type        = string
  default     = "rds-credentials"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
