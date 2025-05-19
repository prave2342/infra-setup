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

# Code Structure

```text
.
├── main.tf         # Core resources like VPC, subnets, gateways, EKS cluster, nodes, jumpbox, ECR repo, IAM roles & policies
├── variables.tf    # Variable definitions for CIDRs, AZs, names, instance types, keys, and other configs
└── provider.tf     # AWS provider configuration and backend setup for Terraform Cloud

# **Code Structure Code StructureTraefik Ingress Setup on EKS**

This setup configures Traefik as the ingress controller on an EKS cluster using the following components:

- **ServiceAccount & RBAC**  
  Creates a service account for Traefik and defines cluster roles and role bindings that allow Traefik to watch and manage Kubernetes resources like services, ingresses, secrets, and Traefik CRDs.

- **IngressClass**  
  Registers Traefik as an ingress controller for Kubernetes ingress resources.

- **Service**  
  Exposes Traefik through an AWS Network Load Balancer (NLB) configured with Elastic IPs for stable public IP addresses. It listens on ports 80 (HTTP), 443 (HTTPS), and 8080 (dashboard/admin).

- **Deployment**  
  Deploys Traefik pods with arguments enabling the dashboard, access logs, HTTP and HTTPS entry points, TLS termination, and support for Kubernetes CRDs with cross-namespace ingress capability.

- **Middleware**  
  Redirects all HTTP traffic to HTTPS to enforce secure connections.

- **IngressRoute**  
  Uses Traefik's Custom Resource Definition (CRD) to route incoming requests for your host (e.g., `live.cddemo.com`) to the Traefik dashboard service, applying HTTPS redirects.

## **Domain and DNS Setup**

- The domain **`cdemo.com`** is managed in **AWS Route 53**.
- An **Elastic IP** is allocated and associated with the AWS Network Load Balancer (NLB) created by the Traefik Service of type LoadBalancer.
- A **CNAME record** (e.g., `live`) is created in Route 53, pointing to the NLB’s DNS name or the Elastic IP.
- This creates the fully qualified domain name (FQDN) **`live.cdemo.com`**, which is used in the Traefik IngressRoute to route external traffic into the cluster.

This setup ensures:
- Stable IP via Elastic IP for the NLB
- Friendly DNS name for accessing the services behind Traefik ingress

## **Jenkins Deployment Summary**

### Custom Jenkins Image
- Based on `jenkins/jenkins:lts`
- Installs Docker, Git, Maven, AWS CLI, kubectl (ARM64)
- Adds Jenkins user to Docker group

### Helm Deployment
- Runs Jenkins + Docker-in-Docker (`dind`) sidecar container (privileged)
- Uses PVC for Jenkins data persistence
- Exposes Jenkins via Traefik IngressRoute at `https://live.cddemo.com/jenkins`
- Connects Jenkins to Docker daemon on `tcp://localhost:2375`

### Service Account & RBAC
- ServiceAccount: `jenkins-sa` in `jenkins` namespace
- ClusterRole with permissions to manage pods, services, deployments, jobs, autoscaling, and Traefik ingressroutes
- ClusterRoleBinding links `jenkins-sa` to this ClusterRole


## **Jenkins Endpoint

- Jenkins is exposed via Traefik IngressRoute.
- Accessible at: `https://live.cddemo.com/jenkins`
- Jenkins service is reachable through Traefik on port defined in the Helm chart (usually 8080).
- This setup ensures secure, scalable, and manageable access to Jenkins running inside the EKS cluster.
