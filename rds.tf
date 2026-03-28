# RDS Subnet Group
resource "aws_db_subnet_group" "rds" {
  name       = "${local.cluster_name}-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${local.cluster_name}-rds-subnet-group"
  }
}

# KMS Key for RDS
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = var.rds_instance_id

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  db_name  = var.rds_database_name
  username = var.rds_master_username
  password = random_password.rds_password.result

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false
  publicly_accessible = false

  tags = {
    Name = var.rds_instance_id
  }
}