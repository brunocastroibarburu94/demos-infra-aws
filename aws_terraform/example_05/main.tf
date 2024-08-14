data "aws_caller_identity" "current_account" {}

output "account_id" {
  value = data.aws_caller_identity.current_account.account_id
}

#######################
##### Repository ######
#######################

data "aws_ecr_repository" "ecr_repo" {
  name = var.ecr_name
}

output "ecr_url" {
  value = data.aws_ecr_repository.ecr_repo.repository_url
  description = "ECR repo URL"
}

output "ecr_latest_tags" {
  value = data.aws_ecr_repository.ecr_repo.most_recent_image_tags[0]
  description = "Most recent image tags"
}

#########################
##### Role for EC2 ######
#########################

# IAM role for the EC2
resource "aws_iam_role" "ec2_app_role" {
  name = "ec2-app-role"
  # This allows any EC2 instance to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "ec2_app_role_policy" {
  name = "ec2_app_role_policy"
  # Indicates the roles that this policy applies to
  role = aws_iam_role.ec2_app_role.id
  # Policy:
  #   - Read only to ECR
  #   - Allow log propagation
  policy =  <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:ListTagsForResource",
                "ecr:DescribeImageScanFindings"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "logs:CreateLogGroup"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}


// Sends your public key to the instance
resource "aws_key_pair" "key-pair" {
    key_name = "key-pair"
    public_key = file(var.public_key_path)
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-app-instance-profile"
  role = aws_iam_role.ec2_app_role.name
}

################
##### EC2 ######
################

output "user_data_compiled" {
  value = templatefile("./launch_app.template",{
    REGION : var.aws_region,
    ECR_TARGET: data.aws_ecr_repository.ecr_repo.repository_url
    }
  ) 
  
  description = "Script to be execute by EC2 instance once initialized"
}

resource "aws_instance" "web1" {
    ami =  "ami-0dc7807d04b7623e7" # Amazon ECS-Optimized Amazon Linux 2023 (AL2023) x86_64 AMI
    instance_type = "t2.small"
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
    # VPC
    subnet_id = aws_subnet.prod-subnet-public-05-1.id
    # Security Group
    vpc_security_group_ids = [aws_security_group.security_group.id]
    # the Public SSH key
    key_name = aws_key_pair.key-pair.id
    # Run the App at the start of the service
    user_data =  templatefile("./launch_app.template",{
      REGION : var.aws_region,
      ECR_TARGET: data.aws_ecr_repository.ecr_repo.repository_url
    }
  ) 
}