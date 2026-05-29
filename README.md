Main issue: extra nested ````markdown block and duplicate setup command at the end. Fixed version below. 

````markdown
# Complete RDS Password Rotation for Kubernetes

This Terraform project creates everything from scratch:

- VPC with public/private subnets
- EKS cluster with node group
- RDS MySQL instance
- Lambda function for password rotation
- EventBridge scheduler
- External Secrets Operator
- Stakater Reloader
- Example application

## Architecture

```mermaid
graph TB
    subgraph "AWS Account"
        subgraph "VPC"
            subgraph "Public Subnets"
                NAT["NAT Gateway"]
            end

            subgraph "Private Subnets"
                EKS["EKS Cluster"]
                RDS[("RDS MySQL<br/>Instance")]
            end
        end

        EB["EventBridge<br/>Scheduler"]
        Lambda["Lambda Function<br/>Password Rotation"]
        SSM["AWS SSM Parameter Store<br/>SecureString RDS Password"]
        IAM["IAM Roles &<br/>Policies"]
        OIDC["EKS OIDC Provider<br/>IRSA"]
    end

    subgraph "EKS Cluster Components"
        ESO["External Secrets<br/>Operator"]
        Reloader["Stakater<br/>Reloader"]
        App["Example Application<br/>Secret Consumer"]
        K8SSecret["Kubernetes Secret<br/>RDS Credentials"]
    end

    EB -->|Triggers| Lambda
    Lambda -->|ModifyDBInstance API<br/>Rotates Password| RDS
    Lambda -->|Updates SecureString| SSM

    SSM -->|Syncs every 5 min| ESO
    ESO -->|Creates / Updates| K8SSecret
    K8SSecret -->|Secret Change Detected| Reloader
    Reloader -->|Restarts Pods| App
    App -->|Connects using new password| RDS

    IAM -.->|Grants Lambda Permissions| Lambda
    IAM -.->|Grants EventBridge Invoke Permission| EB
    IAM -.->|Creates IRSA Role| OIDC
    OIDC -.->|AssumeRoleWithWebIdentity| ESO
````

## Prerequisites

* AWS account with credentials configured
* Terraform installed
* kubectl, Helm, and AWS CLI installed

## Deployment and Validation Guide

### 1. Launch Ubuntu EC2 and Clone Repository

```bash
git clone https://github.com/imagefactory-web/rds-password-rotation.git
cd rds-password-rotation
```

### 2. Install Required Tools

```bash
chmod +x scripts/setup-k8s-tools.sh
./scripts/setup-k8s-tools.sh
```

### 3. Verify Terraform Backend

Before running Terraform, check `provider.tf` and update the backend with your S3 bucket and region.

```hcl
backend "s3" {
  bucket = "your-terraform-state-bucket"
  key    = "state.tfstate"
  region = "ap-south-2"
}
```

### 4. Deploy AWS Infrastructure

```bash
terraform init
terraform plan
terraform apply --auto-approve
```

After successful apply, Terraform will print outputs such as:

```text
cluster_name
cluster_endpoint
lambda_function_name
rds_endpoint
ssm_parameter_path
external_secrets_role_arn
```

### 5. Update kubeconfig

Replace the cluster name and region with values from your Terraform output.

```bash
aws eks update-kubeconfig \
  --name myapp-5u975y \
  --region ap-south-2
```

Verify cluster connectivity:

```bash
kubectl get nodes
```

### 6. Deploy Kubernetes Components

```bash
cd k8s
terraform init
terraform plan
terraform apply --auto-approve
```

### 7. Verify Kubernetes Secret

```bash
kubectl get secret rds-credentials -n applications
kubectl describe secret rds-credentials -n applications
```

### 8. Check Current RDS Password in SSM

```bash
aws ssm get-parameter \
  --name "/myapp/rds-password" \
  --with-decryption \
  --region ap-south-2
```

Note these values before rotation:

```text
Value
Version
LastModifiedDate
```

### 9. Invoke Lambda for Password Rotation

```bash
aws lambda invoke \
  --function-name myapp-password-rotation \
  --cli-binary-format raw-in-base64-out \
  --payload '{}' \
  --region ap-south-2 \
  response.json
```

Check Lambda response:

```bash
cat response.json
```

Expected response:

```json
{
  "statusCode": 200,
  "body": "{\"message\":\"Password rotation completed successfully\"}"
}
```

### 10. Verify Updated Password in SSM

```bash
aws ssm get-parameter \
  --name "/myapp/rds-password" \
  --with-decryption \
  --region ap-south-2
```

Validate:

```text
Version number should increase
LastModifiedDate should update
Password value should change
```

### 11. Verify RDS Status

```bash
aws rds describe-db-instances \
  --db-instance-identifier myapp-database \
  --region ap-south-2 \
  --query "DBInstances[0].DBInstanceStatus"
```

Expected output:

```text
available
```

### 12. Test MySQL Connectivity from EKS

```bash
kubectl run mysql-client -it --rm \
  --image=mysql:8 \
  --restart=Never \
  -- mysql \
  -h myapp-database.clme62qos4zc.ap-south-2.rds.amazonaws.com \
  -u admin \
  -p
```

Enter the latest password from SSM.

Expected output:

```text
Welcome to the MySQL monitor.
```

Run inside MySQL:

```sql
SELECT USER();
SHOW DATABASES;
exit;
```

### 13. Verify External Secrets Sync

```bash
kubectl get externalsecrets -A
kubectl describe externalsecret rds-credentials -n applications
kubectl get secret rds-credentials -n applications
```

### 14. Verify Application Restart by Reloader

```bash
kubectl get deployments -n applications
kubectl get pods -n applications
```

Reloader should restart the application pod after the Kubernetes secret is updated.

## End-to-End Flow

```text
Lambda invoked
    ↓
RDS password rotated
    ↓
SSM Parameter Store updated
    ↓
External Secrets Operator syncs secret
    ↓
Kubernetes Secret updated
    ↓
Stakater Reloader restarts application pod
    ↓
Application uses new password
```
```
```
