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

    style EKS fill:#FF9900,stroke:#333,color:#fff
    style RDS fill:#527FFF,stroke:#333,color:#fff
    style Lambda fill:#FF9900,stroke:#333,color:#fff
    style SSM fill:#527FFF,stroke:#333,color:#fff
    style EB fill:#FF9900,stroke:#333,color:#fff
    style K8SSecret fill:#7B68EE,stroke:#333,color:#fff
```

## Prerequisites

- AWS account with credentials configured
- Terraform installed
- kubectl, helm, and AWS CLI (setup script included)

## Quick Setup

### 1. Install prerequisites

```bash
chmod +x scripts/setup-k8s-tools.sh
./scripts/setup-k8s-tools.sh
