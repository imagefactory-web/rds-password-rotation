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
        SM["AWS Secrets Manager<br/>RDS Password"]
        IAM["IAM Roles &<br/>Policies"]
    end
    
    subgraph "EKS Cluster Components"
        ESO["External Secrets<br/>Operator"]
        Reloader["Stakater<br/>Reloader"]
        App["Example<br/>Application"]
    end
    
    EB -->|Triggers| Lambda
    Lambda -->|Updates Secret| SM
    Lambda -->|Rotates Password| RDS
    SM -->|Syncs| ESO
    ESO -->|Creates K8s Secret| Reloader
    Reloader -->|Reloads| App
    App -->|Connects| RDS
    IAM -.->|Grants Permissions| Lambda
    IAM -.->|Grants Permissions| ESO
    
    style EKS fill:#FF9900,stroke:#333,color:#fff
    style RDS fill:#527FFF,stroke:#333,color:#fff
    style Lambda fill:#FF9900,stroke:#333,color:#fff
    style SM fill:#527FFF,stroke:#333,color:#fff
    style EB fill:#FF9900,stroke:#333,color:#fff
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