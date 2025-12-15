resource "aws_ecr_repository" "communication" {
  name                 = "schools-communication-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_communication_url" {
  value = aws_ecr_repository.communication.repository_url
}
