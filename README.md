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
```
## Traefik Ingress Setup on EKS

This setup configures Traefik as the ingress controller on an EKS cluster using:

- **ServiceAccount & RBAC**  
  Creates Traefik service account and cluster roles/role bindings for required Kubernetes resource access.

- **IngressClass**  
  Registers Traefik as the ingress controller.

- **Service**  
  Exposes Traefik via an AWS Network Load Balancer (NLB) with Elastic IPs on ports 80, 443, and 8080.

- **Deployment**  
  Deploys Traefik pods with dashboard, TLS termination, HTTP->HTTPS redirect, and Kubernetes CRD support.

- **Middleware**  
  Redirects HTTP traffic to HTTPS.

- **IngressRoute**  
  Routes requests to `live.cddemo.com` with HTTPS enforced.

## Domain and DNS Setup

- Domain **`cdemo.com`** managed in **AWS Route 53**.
- Elastic IP(s) allocated and associated with the Traefik NLB.
- CNAME record `live` points to the NLB’s DNS or Elastic IP.
- Creates fully qualified domain name (FQDN) **`live.cddemo.com`** used in Traefik ingress routes.

Benefits:  
- Stable IP via Elastic IP  
- Friendly DNS for accessing services behind Traefik

---

# Traefik Dashboard Endpoint

- **URL:** `https://live.cddemo.com/dashboard/`  
  (Accessible via the same Traefik Ingress setup)

- **Purpose:**  
  The Traefik dashboard provides real-time visibility into the routing configuration and health of the cluster's ingress layer.

- **Key Features:**
  - **Routers:** View all HTTP/S routers that define how requests are matched and forwarded.
  - **Middlewares:** Inspect middlewares like HTTP->HTTPS redirection, authentication, etc.
  - **Services:** See the backend services exposed by IngressRoutes (e.g., Jenkins).
  - **EntryPoints:** Check which ports (like websecure/443) are exposed.

## Jenkins Deployment Summary

- **Custom Jenkins Image:**  
  Based on `jenkins/jenkins:lts` with Docker, Git, Maven, AWS CLI, and ARM64 `kubectl` installed. Jenkins user added to Docker group.

- **Helm Deployment:**  
  Runs Jenkins + Docker-in-Docker sidecar 
  Persistent storage via PVC  
  Exposed via Traefik IngressRoute at `https://live.cddemo.com/jenkins`  
  Jenkins connects to Docker daemon at `tcp://localhost:2375`

- **Service Account & RBAC:**  
  ServiceAccount `jenkins-sa` in `jenkins` namespace  
  ClusterRole with broad Kubernetes permissions including Traefik ingressroutes  
  ClusterRoleBinding binds `jenkins-sa` to the ClusterRole

# Jenkins Endpoint

- Exposed via Traefik IngressRoute  
- Accessible at `https://live.cddemo.com/jenkins`  


