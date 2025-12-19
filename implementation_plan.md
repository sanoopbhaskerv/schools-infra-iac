# Cost Optimization Implementation Plan

## Goal
Reduce AWS EC2 and Network costs for the Development environment by approx. 60-80%.
**Target Savings**: ~$40-60/month.

## User Review Required
> [!WARNING]
> This change alters the network topology.
> 1.  **Security**: Backend services will technically be in "Public" subnets (routed to IGW). We rely on **Security Groups** to block unauthorized access.
> 2.  **Public IPs**: All containers will receive a Public IPv4 address.
> 3.  **Spot Instances**: We will switch to Fargate Spot, which has a small risk of interruption.

## Proposed Changes

### 1. Network Topology (`vpc.tf`)
-   **Modify**: `aws_subnet.private`
    -   Set `map_public_ip_on_launch = true`.
-   **Remove**: `aws_nat_gateway.nat` and `aws_eip.nat`.
-   **Modify**: `aws_route_table.private`
    -   Change route `0.0.0.0/0` target from `nat_gateway_id` to `aws_internet_gateway.gw.id`.
    -   (Effectively making them public subnets, keeping the name "private" to avoid breaking lookups).

### 2. AWS Variables (`variables.tf`)
-   **Remove**: `single_nat_gateway` variable (unused after change).
-   **Add/Update**: Ensure defaults support the new topology if needed.

### 3. ECS Services (Compute)
We will update `launch_type` to `FARGATE_SPOT` (or use Capacity Provider strategy) and enable public IPs for **ALL** services in `schools-infra-iac`.

**Affected Files**:
-   `ecs.tf` (Admin Service)
-   `gateway.tf`
-   `academic.tf`
-   `communication.tf`
-   `fee.tf`
-   `student-frontend.tf`
-   `teacher-frontend.tf`

**Changes per file**:
```hcl
resource "aws_ecs_service" "..." {
  # ...
  # Change Launch Type
  # launch_type = "FARGATE"  <-- DELETE or COMMENT OUT

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  network_configuration {
    # ...
    assign_public_ip = true   # <-- CHANGE to TRUE (Required for pulling images without NAT)
  }
}
```

## Verification Plan

### Automated Verification
-   Run `terraform validate` to ensure syntax is correct.
-   Run `terraform plan` to verify:
    -   `aws_nat_gateway` will be destroyed.
    -   `aws_eip` will be destroyed.
    -   `aws_route_table` routes change.
    -   ECS Services updates (might require replacement if launch type changes).

### Manual Verification
-   Since I cannot execute `terraform apply` against your real AWS account, I will leave the code in a ready-to-apply state.
-   You (User) will run: `cd infrastructure/schools-infra-iac && terraform apply`.
