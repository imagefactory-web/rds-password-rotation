# Generate random password for RDS
resource "random_password" "rds_password" {
  length  = 16
  special = false
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  cluster_name = "${var.project_name}-${random_string.suffix.result}"
  vpc_name     = "${var.project_name}-vpc-${random_string.suffix.result}"
}