resource "aws_ecr_repository" "prod_ecr_repo" {
  name                 = "prod-ecr-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_url" {
  value = aws_ecr_repository.prod_ecr_repo.repository_url
  description = "The URL of the ECR repository."
}