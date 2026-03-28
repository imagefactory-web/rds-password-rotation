aws_region           = "ap-south-2"
project_name         = "myapp"
rds_instance_id      = "myapp-database"
rds_master_username  = "admin"
rds_database_name    = "myappdb"
kubernetes_namespace = "applications"

tags = {
  Environment = "dev"
  ManagedBy   = "terraform"
  Project     = "rds-password-rotation"
}