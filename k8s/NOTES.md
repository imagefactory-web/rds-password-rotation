# RDS Password Rotation on Kubernetes - Trainer Notes

## k8S Folder Break Down

# Module 1 - Provider Configuration

## File

providers.tf

## Purpose

Terraform needs to know:

* Which EKS cluster to connect to
* Which AWS account to use
* How to authenticate

### Kubernetes Provider

```hcl
provider "kubernetes"
```

Used to create:

* Namespaces
* Service Accounts
* Deployments

### Helm Provider

```hcl
provider "helm"
```

Used to install:

* External Secrets Operator
* Reloader

### Kubectl Provider

```hcl
provider "kubectl"
```

Used to deploy CRDs like:

* ClusterSecretStore
* ExternalSecret

### Remote State

```hcl
data "terraform_remote_state" "eks"
```

Reads outputs from the infrastructure Terraform.

Example:

```text
Cluster Name
Cluster Endpoint
Cluster CA
IRSA Role ARN
```

---

# Module 2 - Terraform Backend

## File

main.tf

## Purpose

Store Terraform state remotely.

```hcl
backend "s3"
```

Benefits:

* Shared state
* Team collaboration
* State recovery
* CI/CD support

---

# Module 3 - Variables

## File

variables.tf

## Purpose

Avoid hardcoding values.

Example:

```hcl
variable "aws_region"
```

Instead of:

```text
ap-south-2
```

being hardcoded everywhere.

Other examples:

```text
project_name
kubernetes_namespace
rds_instance_id
rotation_schedule
```

Benefits:

* Reusable
* Environment-specific
* Easier maintenance

---

# Module 4 - Namespaces

## File

kubernetes.tf

### External Secrets Namespace

```hcl
external-secrets
```

Used to run:

External Secrets Operator

---

### Reloader Namespace

```hcl
reloader
```

Used to run:

Stakater Reloader

---

### Applications Namespace

```hcl
applications
```

Used to run:

Business applications

---

# Module 5 - IRSA

## Service Account

```hcl
kubernetes_service_account
```

Important annotation:

```hcl
eks.amazonaws.com/role-arn
```

This enables:

IRSA

IAM Roles for Service Accounts

---

## Why IRSA?

Without IRSA:

```text
Store AWS keys inside Kubernetes
```

Bad practice.

With IRSA:

```text
Pod receives temporary credentials
```

Secure and production-ready.

---

# Module 6 - External Secrets Operator

## File

helm.tf

Installed using:

```hcl
helm_release.external_secrets
```

---

## What ESO Does

Reads secrets from:

```text
AWS SSM Parameter Store
```

Creates:

```text
Kubernetes Secret
```

Automatically.

---

### Example

SSM:

```text
/myapp/rds-password
```

↓

Kubernetes Secret:

```text
rds-credentials
```

---

# Module 7 - ClusterSecretStore

## File

kubernetes.tf

```yaml
kind: ClusterSecretStore
```

Think of this as:

Connection configuration.

It tells ESO:

```text
Where are my secrets?
```

Answer:

```text
AWS SSM Parameter Store
```

---

# Module 8 - External Secret

## File

kubernetes.tf

```yaml
kind: ExternalSecret
```

Defines:

```text
What secrets should be imported?
```

Example:

```text
/myapp/rds-username
/myapp/rds-password
/myapp/rds-host
```

Creates:

```text
rds-credentials
```

Kubernetes Secret.

---

# Module 9 - Secret Refresh

```yaml
refreshInterval: 5m
```

Every 5 minutes:

ESO checks SSM.

If value changed:

Update Kubernetes Secret.

---

# Module 10 - Application Deployment

## File

kubernetes.tf

Application:

```hcl
nginx:latest
```

Used as demo application.

---

### Environment Variables

Injected from Secret:

```text
DB_HOST
DB_USERNAME
DB_PASSWORD
```

Application never directly reads SSM.

It only reads Kubernetes Secret.

---

# Module 11 - Stakater Reloader

## File

helm.tf

Installed using:

```hcl
helm_release.reloader
```

---

## Problem

Secret updated.

Pod still running.

Pod still uses old password.

---

## Solution

Reloader watches:

```text
Secrets
ConfigMaps
```

When Secret changes:

```text
Deployment Restart
```

Automatically.

---

## Annotation

```yaml
reloader.stakater.com/auto: "true"
```

This tells Reloader:

```text
Watch this deployment
```

---

# Password Rotation Scenario

## Before Rotation

```text
SSM Password = abc123

Kubernetes Secret = abc123

Application = abc123
```

---

## Lambda Runs

```text
New Password = xyz789
```

Stored in:

```text
SSM Parameter Store
```

---

## ESO Sync

```text
Kubernetes Secret = xyz789
```

---

## Reloader Detects Change

```text
Pod Restart
```

---

## Application Starts

```text
DB_PASSWORD = xyz789
```

Everything works.

No manual action.

---

# Why This Project Matters

This project demonstrates:

* Terraform
* Kubernetes
* Helm
* IRSA
* External Secrets Operator
* Stakater Reloader
* AWS Lambda
* SSM Parameter Store
* RDS
* EventBridge

This structure is ideal for a 45–60 minute classroom session because it explains the *why*, *what*, and *how* of each component rather than just reading Terraform code line by line.
