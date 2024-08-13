
#####################################
#######      IAM for Task    ########
#####################################
data "aws_iam_policy_document" "ecs_task_role_assume_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  # Policy that indicates who can assume this role
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_policy_document.json
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "ecs_task_role_policy"
  # Indicates the roles that this policy applies to
  role = aws_iam_role.ecs_task_role.id
  # Policy
  policy =  <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "ecr:GetAuthorizationToken"
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

resource "aws_iam_instance_profile" "ecs_task_instance_profile" {
  name = "ecs_task_instance_profile"
  role = aws_iam_role.ecs_task_role.name
}

#############################################################################################

data "aws_iam_policy_document" "ecs_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name = "ecs_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_role_policy_document.json
}

resource "aws_iam_role_policy" "ecs_role_policy" {
  name = "ecs_role_policy"
  role = aws_iam_role.ecs_role.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsInstanceRole" {
    name = "ecsInstanceRole"
    assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs_instance_profile"
  role = aws_iam_role.ecsInstanceRole.name
}

resource "aws_kms_key" "example" {
  description             = "example"
  deletion_window_in_days = 7
}

# ECS
resource "aws_ecs_cluster" "prod-ecs-cluster-03" {
  name = "my-ecs-cluster-03"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.example.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.my_log_group.name
        s3_bucket_name = aws_s3_bucket.prod-ecs-logs-03.bucket
      }
    }
  }
}

# Create capacity provider for ECS clusters
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "test1"

 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 3
   }
 }
}

# Link ECS cluster to capcity provider
resource "aws_ecs_cluster_capacity_providers" "example" {
 cluster_name = aws_ecs_cluster.prod-ecs-cluster-03.name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
 }
}