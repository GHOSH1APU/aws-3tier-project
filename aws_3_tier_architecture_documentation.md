# Highly Available AWS 3-Tier Architecture

This repository contains the Infrastructure as Code (IaC) to automatically provision a secure, highly available, and scalable 3-tier web application architecture on AWS. The infrastructure is defined using **Terraform** and deployed continuously via **GitHub Actions** using OpenID Connect (OIDC) authentication.

## 🏗️ Architecture Overview

The architecture spans two Availability Zones (`us-east-1a`, `us-east-1b`) for high availability and strict network isolation across three distinct tiers:

1. **Presentation Tier (Tier 1 - Public):** 
   - Public subnets containing an **Application Load Balancer (ALB)** and NAT Gateways.
   - Accepts incoming HTTP/HTTPS traffic from the internet and routes it to the application tier.
   - Custom domain routing managed via **Amazon Route 53** (`ghoshsourav21.in`).

2. **Application Tier (Tier 2 - Private):** 
   - Private subnets hosting Amazon Linux 2023 EC2 instances managed by an **Auto Scaling Group (ASG)**.
   - Instances are bootstrapped with a Launch Template running Apache and PHP to dynamically render data.
   - **AWS Systems Manager (SSM)** is used for secure shell access without requiring public IP addresses or SSH keys.

3. **Database Tier (Tier 3 - Isolated):** 
   - Highly restricted private subnets hosting an **Amazon RDS MySQL** database (`appdatabase`).
   - Accessible *only* from the Application Tier.

## 🛡️ Security Group Chaining

Security is enforced using strict Security Group chaining:
* **ALB SG:** Allows inbound traffic on Port 80 (and 443) from `0.0.0.0/0`.
* **App SG:** Allows inbound traffic on Port 80 *only* from the ALB SG.
* **DB SG:** Allows inbound traffic on Port 3306 (MySQL) *only* from the App SG.

## 📂 Project Structure

```text
.
## 📂 Repository Structure

The Terraform codebase utilizes a dedicated networking module alongside root-level resource definitions to provision the 3-tier environment:

## 📂 Repository Structure

The Terraform codebase utilizes a dedicated networking module for complex routing, while core compute, database, and security resources are defined at the root level for streamlined deployment:

```text
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions CI/CD pipeline definition
├── modules/
│   └── vpc/                # Dedicated networking and routing module
│       ├── ngw.tf          # NAT Gateway provisioning for private subnets
│       ├── outputs.tf      # Network state outputs
│       ├── routetable.tf   # Route table definitions
│       ├── rt-ngw-igw.tf   # Route table associations (IGW and NGW)
│       └── vpccreation.tf  # Core VPC and subnet creation
├── alb.tf                  # Application Load Balancer configuration
├── asg.tf                  # Auto Scaling Group and Launch Template configuration
├── aws_3_tier_architecture_documentation # Project architecture and documentation
├── main.tf                 # Root configuration calling the VPC module 
├── provider.tf             # AWS provider configuration and region setup
├── rds.tf                  # Amazon RDS MySQL database configuration
└── security_groups.tf      # Security group definitions restricting access between tiers
```

## 🚀 Deployment Instructions

### Prerequisites
- An AWS Account (`429134228003`).
- Terraform configured remotely (e.g., S3 backend).
- GitHub Repository connected to AWS IAM via OIDC (`Githubactios-Terraform-3-tier-Role`).

### Automated Deployment (CI/CD)
This project uses GitHub Actions for continuous deployment.
1. Any push to the `main` branch will automatically trigger the `deploy.yml` workflow.
2. The pipeline authenticates with AWS via OIDC, runs `terraform init`, `terraform plan`, and `terraform apply -auto-approve`.

### Manual / Local Execution
If executing locally (assuming you have the correct AWS credentials configured):
```bash
# Initialize the Terraform working directory
terraform init

# Review the execution plan
terraform plan

# Provision the infrastructure
terraform apply
```

## 🧹 Cleanup & Cost Management

To prevent ongoing AWS charges (especially for the NAT Gateways, ALB, and RDS instances), you must destroy the infrastructure when it is not in use. 

Trigger the destroy process by updating the GitHub Actions pipeline to run:
```bash
terraform destroy -auto-approve
```
*(If running locally, ensure your backend state is synced by running `terraform init -reconfigure` first).*

## 👨‍💻 Author
**Sourav Ghosh** 
All resources deployed by this project are globally tagged with `Owner = "Sourav Ghosh"`.