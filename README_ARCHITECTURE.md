# SmartSchool Platform Architecture

## Overview
SmartSchool is a cloud-native, microservices-based platform designed to manage school operations, including student management, fee processing, and administrative tasks. The platform is deployed on AWS using a modern containerized architecture.

## System Architecture

### High-Level Architecture
The system follows a typical 3-tier microservices architecture:
1.  **Presentation Layer**: Web and Mobile Applications.
2.  **API Gateway Layer**: Centralized entry point for routing, authentication, and load balancing.
3.  **Service Layer**: Independent microservices handling specific business domains.
4.  **Data Layer**: Relational databases for persistent storage.

### Component Diagram

```mermaid
graph TD
    ClientWeb[Admin Web App\n(React/Vite)] --> ALB[AWS Application Load Balancer]
    ClientMobile[Student Mobile App\n(React Native)] --> ALB
    
    ALB --> GatewayService[Gateway Service\n(Spring Boot / Netty)]
    
    subgraph VPC [AWS VPC]
        subgraph Public Subnets
            ALB
            GatewayService
        end
        
        subgraph Private Subnets
            GatewayService --> |Service Discovery| AdminService[Admin Service\n(Spring Boot)]
            GatewayService --> |Service Discovery| StudentService[Student Service\n(Spring Boot - Planned)]
            
            AdminService --> RDS[(AWS RDS\nPostgreSQL)]
            StudentService --> RDS
        end
    end
```

## Infrastructure Components (AWS)

### 1. Networking (VPC)
- **VPC**: Custom VPC (`10.0.0.0/16`) hosting all resources.
- **Subnets**:
    - **Public Subnets**: Host the Load Balancer and Gateway Service (ECS Tasks with Public IPs for Fargate).
    - **Security Groups**: Strict egress/ingress rules ensuring only ALB talks to Gateway, and Gateway talks to Internal Services.

### 2. Computing (AWS ECS Fargate)
- **Cluster**: `schools-platform-cluster`
- **Services**:
    - **Gateway Service**: Public-facing entry point. Exposed via ALB.
    - **Admin Service**: Internal implementation of admin logic. Not exposed publicly; reachable only via Gateway.
- **Task Definitions**: Defined via Terraform, using ECR images.

### 3. Load Balancing (ALB)
- **Application Load Balancer**: `schools-platform-alb`
- **Listeners**: Listens on Port 80 (HTTP).
- **Target Groups**:
    - `schools-platform-gateway-tg`: Routes external traffic to the Gateway Service.

### 4. Service Discovery (AWS Cloud Map)
- **Namespace**: `school.local`
- Enables internal microservices to locate each other without hardcoded IPs.
- Example: Gateway calls Admin Service at `http://admin-service.school.local:8080`.

### 5. Storage (RDS)
- **Database**: AWS RDS (PostgreSQL).
- **Instance**: `db.t3.micro`.
- **Connectivity**: Accessible only from ECS Tasks (Security Group rules).

### 6. Logging & Monitoring
- **CloudWatch Logs**: All ECS services stream logs to `/ecs/<service-name>`.

## Microservices Breakdown

### 1. Gateway Service (`schools-gateway-service`)
- **Technology**: Java, Spring Boot, Spring Cloud Gateway.
- **Role**: Reverse Proxy, Traffic Routing.
- **Routing Logic**:
    - Routes `/api/admin/**` -> Admin Service.
    - Routes `/api/student/**` -> Student Service.

### 2. Admin Service (`schools-admin-service`)
- **Technology**: Java, Spring Boot.
- **Role**: Handles core administrative logic (Admissions, Fee Management, Staff).
- **Database**: Connects to `schools-platform-db`.

### 3. Student Service (`schools-student-service`)
- **Technology**: Java, Spring Boot.
- **Role**: Handles student-facing features (View Grades, Pay Fees).
- **Status**: Under Development.

## Frontend Applications

### 1. Admin Web App (`schools-admin-app`)
- **Technology**: React, Vite, TypeScript.
- **UI Library**: Custom / Tailwind.
- **Access**: Consumes APIs via the ALB URL.

### 2. Student Mobile App (`schools-student-app`)
- **Technology**: React Native (Expo).
- **UI Library**: Gluestack UI.
- **Platform**: iOS and Android.

## Security
- **Network Security**: Services run in VPC. Database is isolated.
- **Application Security**: JWT-based authentication (implemented in Admin Service, validated/passed through Gateway).
- **Infrastructure Security**: IAM Roles with least privilege for ECS Task Execution.
