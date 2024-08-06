resource "aws_s3_bucket" "prod-ecs-logs-03" {
  bucket = "bci-prod-ecs-logs-03"
}



resource "aws_ecr_repository" "prod-ecr-03" {
  name                 = "prod-ecr-03"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

