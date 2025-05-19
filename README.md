## Terraform Infrastructure Overview

This Terraform code provisions the AWS infrastrucures.

- VPC with public and private subnets
- Internet Gateway and NAT Gateway for network access
- Security Groups for jumpbox and EKS nodes
- IAM roles and policies for EKS and ECR access
- EKS cluster and managed node group
- Jumpbox EC2 instance with key pair and IAM profile
- ECR repository for container images

The configuration is organized for use with Terraform Cloud.

## Code Structure

```text
.
├── main.tf         # Core resources like VPC, subnets, gateways, EKS cluster, nodes, jumpbox, ECR repo, IAM roles & policies
├── variables.tf    # Variable definitions for CIDRs, AZs, names, instance types, keys, and other configs
└── provider.tf     # AWS provider configuration and backend setup for Terraform Cloud

## **Traefik Ingress Setup on EKS**
