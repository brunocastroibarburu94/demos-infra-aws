
# data "aws_ami" "example" {
#   executable_users = ["self"]
#   most_recent      = true
#   name_regex       = "ubuntu/images-testing/hvm-ssd/ubuntu-jammy-daily-arm64-server-20240802"
#   owners           = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["myami-*"]
#   }

#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# EC2 Launch Template

# resource "aws_iam_instance_profile" "role-instance-profile"{
#     name = var.ECS_ROLE_FOR_EC2
#     role = aws_iam_role.ecs_role.name
# }

# resource "aws_iam_policy" "ecs_policy" {
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

resource "aws_iam_role" "ecsInstanceRole" {
    name = "ecsInstanceRole"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# resource "aws_iam_policy_attachment" "ecs_policy2role" {
#     name = "ecs_policy_to_role_attachment"
#   policy_arn = aws_iam_policy.ecs_policy.arn
#   roles = [aws_iam_role.ecsInstanceRole.arn]
# }

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs_instance_profile"
  role = aws_iam_role.ecsInstanceRole.name
}

resource "aws_key_pair" "key_pair_ec2ecsglog" {
    key_name = "key-pair-ec2ecsglog"
    public_key = file(var.public_key_path)
}

resource "aws_launch_template" "ecs_lt" {
 name_prefix   = "ecs-template"
 image_id      = "ami-0af4aed83a30539fc"
 instance_type = "t3.micro"

 key_name               = aws_key_pair.key_pair_ec2ecsglog.key_name
 vpc_security_group_ids = [aws_security_group.security_group.id]

 iam_instance_profile {
   name = aws_iam_instance_profile.ecs_instance_profile.name
 }

 block_device_mappings {
   device_name = "/dev/xvda"
   ebs {
     volume_size = 30
     volume_type = "gp2"
   }
 }

 tag_specifications {
   resource_type = "instance"
   tags = {
     Name = "ecs-instance"
   }
 }

 user_data = filebase64("${path.module}/ecs.sh")
}
# Auto scaling group
resource "aws_autoscaling_group" "ecs_asg" {
 vpc_zone_identifier = [aws_subnet.prod-subnet-public-03-1.id, aws_subnet.prod-subnet-public-03-2.id]
 desired_capacity    = 2
 max_size            = 3
 min_size            = 1

 launch_template {
   id      = aws_launch_template.ecs_lt.id
   version = "$Latest"
 }

 tag {
   key                 = "AmazonECSManaged"
   value               = true
   propagate_at_launch = true
 }
}

# 
resource "aws_lb" "ecs_alb" {
 name               = "ecs-alb"
 internal           = false
 load_balancer_type = "application"
 security_groups    = [aws_security_group.security_group.id]
 subnets            = [aws_subnet.prod-subnet-public-03-1.id, aws_subnet.prod-subnet-public-03-2.id]
 enable_deletion_protection = false

 tags = {
   Name = "ecs-alb"
 }
}

resource "aws_lb_listener" "ecs_alb_listener" {
 load_balancer_arn = aws_lb.ecs_alb.arn
 port              = 80
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.ecs_tg.arn
 }
}

resource "aws_lb_target_group" "ecs_tg" {
 name        = "ecs-target-group"
 port        = 80
 protocol    = "HTTP"
 target_type = "ip"
 vpc_id      = aws_vpc.prod-vpc-03.id

 health_check {
   path = "/"
 }
}

# ECS
resource "aws_ecs_cluster" "prod-ecs-cluster-03" {
  name = "my-ecs-cluster-03"
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