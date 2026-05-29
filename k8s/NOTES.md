You want raw `.md` content. Copy this directly into `NOTES.md`.

````markdown
# RDS Password Rotation on Kubernetes - Training Notes

## Architecture Overview

```text
EventBridge Scheduler
        ↓
Lambda Function
        ↓
RDS Password Rotation
        ↓
AWS SSM Parameter Store
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

# providers.tf

## Why do we need providers?

Terraform needs providers to communicate with external systems.

### Kubernetes Provider

```hcl
provider "kubernetes"
```

Used to create:

- Namespaces
- Service Accounts
- Deployments

---

### Helm Provider

```hcl
provider "helm"
```

Used to install applications through Helm.

Examples:

- External Secrets Operator
- Stakater Reloader

---

### Kubectl Provider

```hcl
provider "kubectl"
```

Used for Kubernetes custom resources.

Examples:

- ClusterSecretStore
- ExternalSecret

---

### Terraform Remote State

```hcl
data "terraform_remote_state" "eks"
```

Reads outputs from infrastructure deployment.

Examples:

- Cluster Name
- Cluster Endpoint
- Cluster CA Certificate
- External Secrets IAM Role

---

# main.tf

## Terraform Backend

```hcl
backend "s3"
```

Purpose:

- Store Terraform state remotely
- Enable team collaboration
- Recover state if local machine is lost

Current configuration:

```hcl
backend "s3" {
  bucket = "my-terraform-state-suryaa"
  key    = "k8s-state.tfstate"
  region = "ap-south-2"
}
```

---

# variables.tf

## Why Variables?

Avoid hardcoding values.

Example:

```hcl
variable "aws_region"
```

instead of:

```text
ap-south-2
```

hardcoded throughout the code.

---

Common Variables:

```hcl
project_name
aws_region
kubernetes_namespace
rotation_schedule
external_secret_name
kubernetes_secret_name
```

Benefits:

- Reusable
- Flexible
- Easy maintenance

---

# kubernetes.tf

## Namespace Creation

Creates dedicated namespaces.

```hcl
external-secrets
reloader
applications
```

Purpose:

| Namespace | Purpose |
|------------|----------|
| external-secrets | External Secrets Operator |
| reloader | Stakater Reloader |
| applications | Application workloads |

---

## Service Account

```hcl
kubernetes_service_account
```

Creates:

```text
external-secrets-sa
```

Important annotation:

```hcl
eks.amazonaws.com/role-arn
```

Used for:

```text
IRSA (IAM Roles for Service Accounts)
```

---

## Why IRSA?

Without IRSA:

```text
Store AWS Access Keys inside Kubernetes
```

Bad practice.

With IRSA:

```text
Pod receives temporary credentials
```

Secure and recommended by AWS.

---

# ClusterSecretStore

## Purpose

Defines where secrets are stored.

```yaml
kind: ClusterSecretStore
```

Current Provider:

```yaml
service: ParameterStore
```

Meaning:

```text
External Secrets Operator should read secrets from AWS SSM Parameter Store
```

---

# ExternalSecret

## Purpose

Defines which secrets should be synchronized.

```yaml
kind: ExternalSecret
```

Reads:

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

# Refresh Interval

```yaml
refreshInterval: 5m
```

Meaning:

Every 5 minutes ESO checks AWS SSM.

If password changes:

```text
Update Kubernetes Secret
```

Automatically.

---

# Example Application

Deployment:

```hcl
resource "kubernetes_deployment" "example_app"
```

Container:

```yaml
nginx:latest
```

Purpose:

Demo application consuming Kubernetes secrets.

---

## Secret Injection

Environment Variables:

```yaml
DB_HOST
DB_USERNAME
DB_PASSWORD
```

Source:

```yaml
secret_key_ref
```

Application never directly accesses AWS.

It only consumes Kubernetes Secret.

---

# helm.tf

## External Secrets Operator

Installed using:

```hcl
helm_release.external_secrets
```

Purpose:

```text
AWS SSM → Kubernetes Secret
```

Synchronization.

---

## Why Wait For CRDs?

When ESO is installed:

```text
ClusterSecretStore
ExternalSecret
```

CRDs must exist before Terraform creates them.

Terraform waits:

```bash
kubectl wait
```

before proceeding.

---

# Stakater Reloader

Installed using:

```hcl
helm_release.reloader
```

Purpose:

Automatically restart applications when:

- Secret changes
- ConfigMap changes

---

## Problem Without Reloader

```text
SSM Updated
    ↓
Kubernetes Secret Updated
    ↓
Pod Still Running
    ↓
Application Uses Old Password
```

---

## Solution With Reloader

```text
SSM Updated
    ↓
Kubernetes Secret Updated
    ↓
Reloader Detects Change
    ↓
Deployment Restarted
    ↓
Application Uses New Password
```

---

## Reloader Annotation

```yaml
reloader.stakater.com/auto: "true"
```

Meaning:

```text
Watch this deployment for Secret or ConfigMap changes
```

---

# End-to-End Password Rotation Flow

## Before Rotation

```text
SSM Password = abc123

Kubernetes Secret = abc123

Application = abc123
```

---

## Lambda Runs

```text
Generate New Password
```

Example:

```text
xyz789
```

---

## Update RDS

```text
Master Password Changed
```

---

## Update SSM

```text
/myapp/rds-password = xyz789
```

---

## ESO Sync

```text
Kubernetes Secret = xyz789
```

---

## Reloader Detects Change

```text
Deployment Restarted
```

---

## Application Starts

```text
DB_PASSWORD = xyz789
```

Application now uses the new password.

---

# Interview Questions

### Why External Secrets Operator?

To synchronize secrets from AWS SSM into Kubernetes automatically.

---

### Why IRSA?

To provide AWS permissions to pods without storing AWS keys.

---

### Why Stakater Reloader?

Kubernetes does not automatically restart pods when secrets change.

Reloader triggers rolling restarts automatically.

---

### Why SSM Parameter Store?

Centralized secure storage for application secrets.

---

### Why refreshInterval?

Controls how frequently External Secrets Operator checks for updated values.

---

### What happens when password rotates?

```text
Lambda
 ↓
RDS Password Updated
 ↓
SSM Updated
 ↓
ESO Sync
 ↓
Kubernetes Secret Updated
 ↓
Reloader Restart
 ↓
Application Uses New Password
```
````
