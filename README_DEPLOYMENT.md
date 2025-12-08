# SmartSchool Deployment Guide

This document outlines the build and deployment processes for the SmartSchool platform. It covers infrastructure provisioning, automated CI/CD pipelines, and manual management scripts.

## Prerequisites

Before deploying, ensure you have the following installed and configured:
1.  **AWS CLI**: Configured with credentials (`aws configure`).
2.  **Terraform**: v1.0+.
3.  **Docker**: For building images (if running locally).
4.  **Git**: For version control.

## Deployment Workflows

We use a **GitOps-inspired** workflow where infrastructure code (`schools-deployer`) manages the state of the deployment.

### 1. Automated CI/CD (GitHub Actions)

Each microservice repository (`schools-admin-service`, `schools-gateway-service`) has its own **Build Workflow**.

**The Flow:**
1.  **Developer pushes code** to `master` in the Service Repo.
2.  **Service Workflow** (`build-deploy.yaml`):
    *   Builds the Java JAR (Maven).
    *   Builds Docker Image.
    *   Pushes Image to AWS ECR with a unique tag (Commit SHA).
    *   **Triggers Dispatch**: Sends a `repository_dispatch` event to the `schools-deployer` repository.
3.  **Deployer Workflow** (`deploy-<service>.yml` in `schools-deployer`):
    *   Receives the dispatch event with the new `image_tag`.
    *   Updates the Terraform configuration (Task Definition) with the new tag.
    *   Runs `terraform apply` to update the ECS Service.
    *   ECS pulls the new image and deploys the new task.

### 2. Manual Infrastructure Management (Cost Saving)

For development and exploration, we provide a master script to easily spin up and tear down the entire stack to save costs.

**Script Location**: `infrastructure/manage-infra.sh`

#### A. Spin Up (Start of Day)
Provisions networking, database, load balancer, and deploys all services.

```bash
cd infrastructure

# 1. Export Secrets
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
export TF_VAR_db_password="YourSecurePassword123"

# 2. Run Up Command
./manage-infra.sh up
```
*   **Note**: This creates a **FRESH** database. Data from previous sessions is lost (unless `skip_final_snapshot` is disabled in TF).

#### B. Tear Down (End of Day)
Destroys all resources (ALB, RDS, ECS, VPC) to stop billing.

```bash
cd infrastructure
./manage-infra.sh down
```
*   **Warning**: This deletes the database and all data!

#### C. Troubleshooting State
If you encounter "Resource Already Exists" errors (e.g., after a failed destroy), run the fix script to sync Terraform state:

```bash
cd infrastructure
./fix-state.sh
```

## Infrastructure Code Structure

The infrastructure is divided into two logical layers:

### Layer 1: Core Infrastructure (`schools-infra-iac`)
*   **Purpose**: VPC, Subnets, Security Groups, RDS, ALB.
*   **Frequency**: Rarely changes.
*   **State Location**: Local or S3 (BUCKET: `schoolos-deployer-state-980873318600`).

### Layer 2: Service Deployment (`schools-deployer`)
*   **Purpose**: ECS Services, Task Definitions, Service Discovery, Log Groups.
*   **Frequency**: Changes on every code deployment.
*   **State Location**: S3 (Key: `dev/terraform.tfstate`).
*   **Modules**: Uses reusable `ecs-service-deployment` module.

## Secrets Management

*   **GitHub Secrets**: Used in Actions pipelines.
    *   `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
    *   `TF_VAR_DB_PASSWORD`: RDS Password.
    *   `GH_PAT`: Personal Access Token for cross-repo dispatch.
*   **Local Development**: Export `TF_VAR_db_password` in your terminal.
*   **ECS Runtime**: Secrets are injected as Environment Variables (`SPRING_R2DBC_PASSWORD`) into the container definition via Terraform.

## Common Issues & Fixes

1.  **500 Internal Server Error (Login)**:
    *   Likely DB Password Mismatch.
    *   **Fix**: Reset RDS password in Console, update `TF_VAR_DB_PASSWORD` (or env var), and redeploy/restart.
2.  **503 Service Unavailable**:
    *   Gateway not connected to ALB.
    *   **Fix**: Check `schools-deployer` Terraform to ensure `target_group_arn` is set for Gateway Service.
3.  **Terraform Lock Error**:
    *   Another process is running or crashed.
    *   **Fix**: Use `terraform force-unlock <LOCK_ID>` (use with caution).
