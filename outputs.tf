output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets"
  value       = aws_iam_role.external_secrets.arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS instance address"
  value       = aws_db_instance.main.address
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.rotation.function_name
}

output "ssm_parameter_path" {
  description = "SSM parameter path"
  value       = aws_ssm_parameter.rds_password.name
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${var.aws_region}"
}

output "test_rotation_command" {
  description = "Command to test password rotation"
  value       = "aws lambda invoke --function-name ${aws_lambda_function.rotation.function_name} --payload '{}' response.json"
}

output "check_secret_command" {
  description = "Command to check secret in Kubernetes"
  value       = "kubectl get secret ${var.kubernetes_secret_name} -n ${var.kubernetes_namespace}"
}