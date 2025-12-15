resource "aws_ecr_repository" "fee" {
  name                 = "schools-fee-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_fee_url" {
  value = aws_ecr_repository.fee.repository_url
}
