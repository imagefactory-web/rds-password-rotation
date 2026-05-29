#!/bin/bash
set -euo pipefail

# =========================================================
# DevOps Tools + Docker + SonarQube + EKS Setup Script
# Ubuntu 22.04 / 24.04
# =========================================================

echo "================================================="
echo "Updating system packages..."
echo "================================================="

sudo apt update -y
sudo apt upgrade -y

sudo apt install -y \
  unzip \
  curl \
  wget \
  git \
  gnupg \
  lsb-release \
  ca-certificates \
  apt-transport-https \
  software-properties-common \
  maven

# =========================================================
# Install AWS CLI v2
# =========================================================

echo "================================================="
echo "Installing AWS CLI v2..."
echo "================================================="

cd /tmp

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
-o "awscliv2.zip"

unzip -o awscliv2.zip

sudo ./aws/install --update

aws --version

# =========================================================
# Configure AWS CLI
# =========================================================

echo "================================================="
echo "Configure AWS CLI"
echo "================================================="

read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID

read -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""

read -p "Enter AWS Region [ap-south-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-ap-south-1}

read -p "Enter AWS Output Format [json]: " AWS_OUTPUT
AWS_OUTPUT=${AWS_OUTPUT:-json}

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"
aws configure set output "$AWS_OUTPUT"

echo "AWS CLI configured successfully."

# =========================================================
# Install kubectl
# =========================================================

echo "================================================="
echo "Installing kubectl..."
echo "================================================="

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO \
"https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

curl -LO \
"https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"

echo "$(cat kubectl.sha256) kubectl" | sha256sum --check

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

kubectl version --client

# =========================================================
# Install eksctl
# =========================================================

echo "================================================="
echo "Installing eksctl..."
echo "================================================="

curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin

eksctl version

# =========================================================
# Install Helm
# =========================================================

echo "================================================="
echo "Installing Helm..."
echo "================================================="

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version

# Install Terraform
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update -y 

sudo apt-get install terraform
