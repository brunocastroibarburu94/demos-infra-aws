data "aws_ecr_repository" "ecr_repo" {
  name = "prod-ecr-repo"
}

output "ecr_url" {
  value = data.aws_ecr_repository.ecr_repo.repository_url
  description = "ECR repo URL"
}

output "ecr_latest_tags" {
  value = data.aws_ecr_repository.ecr_repo.most_recent_image_tags[0]
  description = "Most recent image tags"
}