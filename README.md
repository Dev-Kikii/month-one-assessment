# TechCorp AWS Infrastructure

Terraform configuration to deploy TechCorp's web application infrastructure on AWS.

## Architecture Overview
- VPC with public and private subnets across 2 availability zones
- Application Load Balancer in public subnets
- Web servers in private subnets
- Database server in private subnet
- Bastion host for secure administrative access
- NAT Gateways for private subnet internet access

## Prerequisites
- Terraform >= 1.0 installed
- AWS CLI installed and configured
- AWS account with appropriate permissions
- SSH key pair created

## Deployment Steps

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/month-one-assessment.git
cd month-one-assessment/terraform-assessment
```

### 2. Configure variables
```bash
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars` with your values:
- Add your IP address for bastion access
- Confirm your region and instance types

### 3. Initialise Terraform
```bash
terraform init
```

### 4. Review the plan
```bash
terraform plan
```

### 5. Deploy the infrastructure
```bash
terraform apply
```
Type `yes` when prompted.

### 6. Access the application
- **Web app**: Visit the `load_balancer_dns` output URL in your browser
- **Bastion SSH**: `ssh -i ~/.ssh/techcorp-key ec2-user@<bastion_public_ip>`
- **Web server SSH**: From bastion: `ssh webadmin@<web_server_private_ip>`
- **DB server SSH**: From bastion: `ssh dbadmin@<db_server_private_ip>`

## Cleanup Instructions
To destroy all created resources:
```bash
terraform destroy
```
Type `yes` when prompted.

⚠️ This will permanently delete all infrastructure and data.

## File Structure
```
terraform-assessment/
├── main.tf                 # All resource definitions
├── variables.tf            # Variable declarations
├── outputs.tf              # Output definitions
├── terraform.tfvars        # Your variable values (not committed)
├── terraform.tfvars.example # Example variable values
├── user_data/
│   ├── web_server_setup.sh # Apache installation script
│   └── db_server_setup.sh  # PostgreSQL installation script
└── README.md               # This file
```