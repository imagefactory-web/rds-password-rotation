resource "aws_kms_key" "secretsmanager" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 7
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "/${var.project_name}/rds-credentials"
  description = "RDS credentials for ${var.project_name}"
  kms_key_id  = aws_kms_key.secretsmanager.arn
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id

  secret_string = jsonencode({
    username = var.rds_master_username
    password = random_password.rds_password.result
    host     = aws_db_instance.main.address
  })
}