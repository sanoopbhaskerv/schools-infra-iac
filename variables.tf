variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name to be used for tagging resources"
  default     = "schools-platform"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "app_port" {
  description = "Port exposed by the docker image"
  default     = 8082
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 1
}

variable "health_check_path" {
  default = "/actuator/health"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "gateway_image_tag" {
  description = "Docker image tag for gateway service"
  type        = string
  default     = "latest"
}

variable "db_name" {
  description = "Name of the database"
  default     = "school_app"
}

variable "db_username" {
  description = "Database username"
  default     = "school_admin"
}

variable "db_password" {
  description = "Database password"
  sensitive   = true
  # No default value to prevent committing secrets to git
}
