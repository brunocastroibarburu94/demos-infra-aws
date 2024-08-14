variable "aws_region" {    
    default = "eu-west-1"
    type = string
    description = "The region of the AWS account"
}

variable "ecr_name" {    
    default = "prod-ecr-repo"
    type = string
    description = "The name of the ECR repository containing the App"
}

variable "public_key_path" {
    description = "Path to the public SSH Key."
    default = "/root/.ssh/demo-e2-key.pub"
}

# variable "rds_db_passord" {
#     description = "Master password for RDS."
# }