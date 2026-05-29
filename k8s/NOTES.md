# RDS Password Rotation on Kubernetes - Class Notes

## Project Objective

This project demonstrates how to automatically rotate an RDS MySQL password and propagate the updated password to Kubernetes applications without manual intervention.

### Traditional Approach

```text
DBA Changes Password
        ↓
DevOps Updates Secret
        ↓
Restart Application
        ↓
Application Uses New Password
```

### Automated Approach

```text
EventBridge
        ↓
Lambda
        ↓
RDS Password Rotation
        ↓
SSM Parameter Store
        ↓
External Secrets Operator
        ↓
Kubernetes Secret
        ↓
Stakater Reloader
        ↓
Application Restart
        ↓
Application Uses New Password
```

---

# Project Components

## providers.tf

### Purpose

Configures Terraform providers required to communicate with AWS and Kubernetes.

### Kubernetes Provider

```hcl
provider "kubernetes"
```

Used for:

* Namespace creation
* Service Accounts
* Deployments

### Helm Provider

```hcl
provider "helm"
```

Used for:

* Installing External Secrets Operator
* Installing Stakater Reloader

### Kubectl Provider

```hcl
provider "kubectl"
```

Used for:

* Creating ClusterSecretStore
* Creating ExternalSecret

### Terraform Remote State

```hcl
data "terraform_remote_state" "eks"
```

Used to retrieve:

* Cluster Endpoint
* Cluster Name
* Cluster CA Certificate
* IRSA Role ARN

---

# main.tf

## Purpose

Defines Terraform backend and required providers.

### S3 Backend

```hcl
backend "s3"
```

Stores Terraform state remotely.

Benefits:

* Team collaboration
* State locking
* State recovery
* CI/CD integration

---

# variables.tf

## Purpose

Defines configurable values.

Examples:

```hcl
variable "aws_region"
variable "project_name"
variable "kubernetes_namespace"
variable "rotation_schedule"
```

Benefits:

* Reusable code
* Environment flexibility
* Easier maintenance

---

# kubernetes.tf

## Purpose

Creates Kubernetes resources.

---

## Namespace Creation

```hcl
resource "kubernetes_namespace"
```

Namespaces:

```
```
