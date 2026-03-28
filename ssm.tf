# KMS Key for SSM
resource "aws_kms_key" "ssm" {
  description             = "KMS key for SSM Parameter Store"
  deletion_window_in_days = 7
}

# SSM Parameters
resource "aws_ssm_parameter" "rds_password" {
  name        = "/${var.project_name}/rds-password"
  description = "RDS master password"
  type        = "SecureString"
  value       = random_password.rds_password.result
  key_id      = aws_kms_key.ssm.arn
  overwrite   = true
}

resource "aws_ssm_parameter" "rds_username" {
  name        = "/${var.project_name}/rds-username"
  description = "RDS master username"
  type        = "String"
  value       = var.rds_master_username
  overwrite   = true
}

resource "aws_ssm_parameter" "rds_host" {
  name        = "/${var.project_name}/rds-host"
  description = "RDS host endpoint"
  type        = "String"
  value       = aws_db_instance.main.address
  overwrite   = true
}