# CI/CD Pipelines

This repository contains reusable GitHub Actions workflows and composite actions for CI/CD pipelines. These pipelines are designed to streamline the deployment process for various AWS services.

## Available Pipelines

### 1. ECS Pipeline
For containerized applications running on Amazon ECS:
- Building Docker images
- Pushing to ECR
- Updating ECS services
- Managing environment variables

Example usage in `.github/workflows/deploy.yml`:
```yaml
name: Deploy ECS on AWS

on:
  push:
    branches: [ development, staging, production ]

jobs:
  run_deploy:
    uses: lugui-co/infra-github-pipelines/ecs@production
    with:
      environment: ${{ github.ref_name }}
    secrets: inherit
```

### 2. Lambda Python Pipeline
For Python-based AWS Lambda functions:
- Python package management
- Dependencies installation
- Lambda function code updates
- Environment configuration

Example usage in `.github/workflows/deploy.yml`:
```yaml
name: Deploy Lambda Python on AWS

on:
  push:
    branches: [ development, staging, production ]

jobs:
  run_deploy:
    uses: lugui-co/infra-github-pipelines/lambda_python@production
    with:
      environment: ${{ github.ref_name }}
    secrets: inherit
```

### 3. Terraform Pipeline
For infrastructure management:
- Terraform plan generation
- Infrastructure deployment
- Workspace management
- State management using S3 and DynamoDB

Example usage in `.github/workflows/deploy.yml`:
```yaml
name: Deploy Terraform on AWS

on:
  push:
    branches: [ development, staging, production ]

jobs:
  run_deploy:
    uses: lugui-co/infra-github-pipelines/.github/workflows/terraform.yml@production
    with:
      environment: ${{ github.ref_name }}
    secrets: inherit
```

Choose the appropriate pipeline based on your application type:
- Use the **ECS pipeline** for containerized applications
- Use the **Lambda Python pipeline** for Python-based serverless functions
- Use the **Terraform pipeline** for infrastructure provisioning

## Setup Instructions

1. Choose and create the appropriate `.github/workflows/deploy.yml` file from the examples above based on your application type.

2. Configure Repository Variables
   - Go to Settings > Secrets and variables > Actions > Variables
   - Add the following variables:
     - `AWS_DEFAULT_REGION`: The AWS region where your services are deployed
     - `SERVICE_NAME`: The name of your service in AWS (optional if it matches the repository name)

3. Configure Organization Secrets
   - Go to Organization Settings > Secrets and variables > Actions > Secrets
   - Create an IAM user in AWS with Administrator permissions
   - Add the following secrets:
     - `AWS_ACCESS_KEY_ID`: The access key ID of the AWS IAM user
     - `AWS_SECRET_ACCESS_KEY`: The secret access key of the AWS IAM user
   - These credentials will be used by the pipelines to deploy resources in AWS

4. Configure GitHub Environments
   - Go to Settings > Environments
   - Create two environments:
     - `development`
     - `production`
   - Configure environment-specific settings and secrets as needed

5. Branch to AWS Account Mapping
   - Commits to different branches will deploy to corresponding AWS accounts:
     - `development` branch → Development AWS account
     - `staging` branch → Staging AWS account
     - `production` branch → Production AWS account

## Requirements

- AWS credentials configured in your GitHub organization secrets
- IAM user with administrator permissions in AWS
- Appropriate AWS permissions for the services being deployed
- GitHub Actions enabled in your repository

## Note

The Terraform pipeline should be used first to create the infrastructure, followed by either the ECS or Lambda pipeline to deploy your application code.