resource "aws_key_pair" "key_pair_ec2ecsglog" {
    key_name = "key-pair-ec2ecsglog"
    public_key = file(var.public_key_path)
}

resource "aws_launch_template" "ecs_lt" {
 name_prefix   = "ecs-template"
 image_id      = "ami-0dc7807d04b7623e7" # Amazon ECS-Optimized Amazon Linux 2023 (AL2023) x86_64 AMI
 instance_type = "t3.medium"

 key_name               = aws_key_pair.key_pair_ec2ecsglog.key_name
 vpc_security_group_ids = [aws_security_group.security_group.id]

 iam_instance_profile {
   name = aws_iam_instance_profile.ecs_task_instance_profile.name
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
 health_check_grace_period = 300
 health_check_type = "EC2"

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