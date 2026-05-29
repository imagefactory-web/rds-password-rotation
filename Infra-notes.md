# Infrastructure Terraform Files - Trainer Notes

This project is divided into multiple Terraform files. Each file has a specific responsibility. Splitting code into multiple files improves readability, maintainability, and collaboration.

---

# providers.tf

## Purpose

Defines how Terraform connects to AWS.

### Responsibilities

* Configure AWS Provider
* Configure AWS Region
* Configure Authentication

Example:

```hcl
provider "aws" {
  region = var.aws_region
}
```

### Why?

Terraform needs credentials and region information before creating resources.

---

# variables.tf

## Purpose

Store reusable variables.

Examples:

```hcl
aws_region
project_name
rds_instance_id
kubernetes_version
rotation_schedule
```

### Why?

Instead of hardcoding values everywhere.

Bad:

```hcl
region = "ap-south-2"
```

Good:

```hcl
region = var.aws_region
```

Benefits:

* Reusable
* Environment independent
* Easy maintenance

---

# terraform.tfvars

## Purpose

Provides actual values to variables.

Example:

```hcl
aws_region = "ap-south-2"

project_name = "myapp"

rds_instance_id = "myapp-database"
```

### Why?

Keep code generic and values configurable.

---

# vpc.tf

## Purpose

Creates networking infrastructure.

### Resources Created

* VPC
* Public Subnets
* Private Subnets
* Internet Gateway
* NAT Gateway
* Route Tables
* Route Associations

---

## VPC

```hcl
resource "aws_vpc"
```

Creates:

```text
10.0.0.0/16
```

Acts as a private network.

---

## Public Subnets

Used for:

```text
NAT Gateway
```

Resources requiring internet access.

---

## Private Subnets

Used for:

```text
EKS Nodes
RDS Database
```

More secure because they are not directly accessible from the internet.

---

## Internet Gateway

Purpose:

```text
Public Internet Access
```

Used by public subnets.

---

## NAT Gateway

Purpose:

```text
Private Subnets → Internet
```

Allows EKS nodes to:

* Pull Docker images
* Access AWS APIs
* Install packages

without being publicly exposed.

---

# security_groups.tf

## Purpose

Acts as virtual firewall.

Controls traffic between resources.

---

## EKS Security Group

```hcl
aws_security_group.eks
```

Purpose:

Protect EKS cluster.

---

## RDS Security Group

```hcl
aws_security_group.rds
```

Purpose:

Protect database.

Allows:

```text
EKS → RDS (3306)
```

Only approved traffic can reach MySQL.

---

# random.tf

## Purpose

Generate secure passwords.

Example:

```hcl
resource "random_password"
```

Used for:

```text
RDS Master Password
```

Benefits:

* Random
* Secure
* No hardcoded credentials

---

# rds.tf

## Purpose

Creates MySQL database.

---

## Resources Created

### RDS Subnet Group

```hcl
aws_db_subnet_group
```

Tells AWS which subnets RDS can use.

---

### KMS Key

```hcl
aws_kms_key
```

Encrypts database storage.

---

### RDS Instance

```hcl
aws_db_instance
```

Creates:

```text
MySQL 8.0
```

Configuration:

* Private
* Encrypted
* Automated backups
* Dedicated security group

---

## Why RDS?

Managed database service.

AWS handles:

* Backups
* Patching
* High availability
* Monitoring

---

# ssm.tf

## Purpose

Stores database information in Parameter Store.

---

## Parameters Created

### Password

```text
/myapp/rds-password
```

Stored as:

```text
SecureString
```

Encrypted.

---

### Username

```text
/myapp/rds-username
```

---

### Host

```text
/myapp/rds-host
```

---

## Why SSM?

Acts as a centralized secrets repository.

Used later by:

```text
External Secrets Operator
```

---

# iam.tf

## Purpose

Defines permissions.

---

## Roles Created

### Lambda Role

Allows:

```text
Modify RDS
Update SSM
Write Logs
```

---

### EventBridge Role

Allows:

```text
Invoke Lambda
```

---

### EKS Role

Allows:

```text
Create and manage EKS cluster
```

---

### Node Group Role

Allows:

```text
Worker Nodes
Pull Images
Join Cluster
```

---

### External Secrets Role (IRSA)

Allows:

```text
Read SSM Parameters
```

without storing AWS keys in Kubernetes.

---

# lambda.tf

## Purpose

Deploy password rotation Lambda.

---

## archive_file

Creates:

```text
lambda.zip
```

from:

```text
lambda/lambda_function.py
```

---

## Lambda Function

Creates:

```text
myapp-password-rotation
```

---

## Environment Variables

```text
RDS_INSTANCE_ID
RDS_USERNAME
SSM_PARAMETER_PATH
```

---

## What Lambda Does

```text
Generate Password
        ↓
Update RDS Password
        ↓
Update SSM Parameter Store
```

---

# eventbridge.tf

## Purpose

Automate password rotation.

---

## EventBridge Scheduler

Creates schedule:

```text
Monthly
Weekly
Daily
```

depending on configuration.

Current value:

```hcl
cron(0 12 L * ? *)
```

Meaning:

```text
Last day of every month
12 PM UTC
```

---

## Lambda Permission

Allows:

```text
EventBridge → Lambda
```

invocation.

Without this:

```text
Scheduler cannot execute Lambda
```

---

# eks.tf

## Purpose

Creates Kubernetes cluster.

---

## EKS Cluster

```hcl
aws_eks_cluster
```

Creates:

```text
Managed Kubernetes Control Plane
```

AWS manages:

* API Server
* ETCD
* Control Plane

---

## Node Group

```hcl
aws_eks_node_group
```

Creates worker nodes.

Example:

```text
2 x t3.medium
```

Responsibilities:

* Run Pods
* Run Applications
* Run External Secrets Operator
* Run Reloader

---

# outputs.tf

## Purpose

Expose useful information.

Examples:

```hcl
cluster_name
cluster_endpoint
rds_endpoint
lambda_function_name
ssm_parameter_path
```

---

## Why Outputs?

After deployment:

```bash
terraform output
```

provides important values.

These outputs are later consumed by:

* Kubernetes Terraform
* Validation steps
* README examples

---

# Complete Infrastructure Flow

```text
Terraform Apply
        ↓
Create VPC
        ↓
Create Security Groups
        ↓
Create RDS
        ↓
Store Secrets in SSM
        ↓
Create Lambda
        ↓
Create EventBridge Scheduler
        ↓
Create EKS Cluster
        ↓
Expose Outputs
        ↓
Deploy Kubernetes Components
        ↓
Password Rotation Fully Automated
```

---

# Interview Question

### Why split Terraform into multiple files?

Benefits:

* Easier maintenance
* Better readability
* Team collaboration
* Separation of concerns

Example:

```text
vpc.tf          → Networking
rds.tf          → Database
eks.tf          → Kubernetes
lambda.tf       → Serverless
iam.tf          → Permissions
ssm.tf          → Secrets
```

This structure follows real-world enterprise Terraform project standards.
