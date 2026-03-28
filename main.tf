# Main Terraform configuration file
# Resources have been split into individual files for better organization:
# - providers.tf: Terraform block and provider configurations
# - random.tf: Random resources and locals
# - vpc.tf: VPC and networking resources
# - security_groups.tf: Security groups
# - iam.tf: IAM roles and policies
# - eks.tf: EKS cluster and node group
# - rds.tf: RDS resources
# - ssm.tf: SSM parameters
# - lambda.tf: Lambda function
# - eventbridge.tf: EventBridge scheduler
#
# Kubernetes resources have been moved to the k8s/ subdirectory:
# - k8s/kubernetes.tf: Kubernetes namespaces and manifests
# - k8s/helm.tf: Helm releases
# - k8s/providers.tf: Kubernetes and Helm providers
#
# To deploy:
# 1. Run terraform apply in the root directory to create AWS resources
# 2. Run terraform apply in the k8s/ directory to deploy Kubernetes resources