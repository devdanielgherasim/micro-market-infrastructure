# AWS Infrastructure with Terraform

This directory contains Terraform configurations for deploying infrastructure on AWS.

## Environment-Specific Remote States

The Terraform configuration in this directory uses environment-specific remote states to isolate different environments (dev, prod, etc.). This is achieved by:

1. Using a generic backend configuration in `providers.tf`:
   ```hcl
   backend "s3" {}
   ```

2. Providing environment-specific backend configurations during initialization in the apply and destroy scripts:
   - For development environment (`apply.sh` and `destroy.sh`):
     ```bash
     terraform init \
       -backend-config="bucket=terraform-microservices1691715-state" \
       -backend-config="key=environments/dev/terraform.tfstate" \
       -backend-config="region=us-east-1"
     ```
   - For production environment (`apply_prod.sh` and `destroy_prod.sh`):
     ```bash
     terraform init \
       -backend-config="bucket=terraform-microservices1691715-state" \
       -backend-config="key=environments/prod/terraform.tfstate" \
       -backend-config="region=us-east-1"
     ```

This approach allows for:
- Separate state files for different environments
- Independent management of each environment
- Reduced risk of accidental changes to production environment

## Usage

### Development Environment

To deploy to the development environment:

```bash
./apply.sh
```

To destroy resources in the development environment:

```bash
./destroy.sh
```

### Production Environment

To deploy to the production environment:

```bash
./apply_prod.sh
```

To destroy resources in the production environment:

```bash
./destroy_prod.sh
```

## Environment-Specific Variables

Environment-specific variables are defined in the `tfvars_files` directory:
- `dev.tfvars`: Variables for the development environment
- `prod.tfvars`: Variables for the production environment

These files define environment-specific settings such as instance types, node counts, and tags.
