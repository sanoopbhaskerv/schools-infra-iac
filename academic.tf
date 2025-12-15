resource "aws_ecr_repository" "academic" {
  name                 = "schools-academic-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_academic_url" {
  value = aws_ecr_repository.academic.repository_url
}
