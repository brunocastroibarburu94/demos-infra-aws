
# IAM role for the ECS task
resource "aws_iam_role" "ecs_task_role_b" {
  name = "ecs-task-role-b"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
 family             = "my-ecs-task"
 network_mode       = "awsvpc"
 
 execution_role_arn = aws_iam_role.ecs_task_role.arn
 task_role_arn = aws_iam_role.ecs_task_role_b.arn
 cpu                = 256
 runtime_platform {
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
 }
 container_definitions = jsonencode([
   {
     name      = "helloWorld"
     image     = "${data.aws_ecr_repository.ecr_repo.repository_url}:${data.aws_ecr_repository.ecr_repo.most_recent_image_tags[0]}"
     cpu       = 256
     memory    = 512
     essential = true
     logConfiguration = {
           logDriver = "awslogs"
           options = {
             awslogs-group = "${aws_cloudwatch_log_group.my_log_group.name}"
             awslogs-region = "eu-west-1"
             awslogs-stream-prefix = "ecs"
           }
     }
     portMappings = [
       {
         containerPort = 80
         hostPort      = 80
         protocol      = "tcp"
       }
     ]
    }
 ])
}

resource "aws_ecs_service" "ecs_service" {
 name            = "my-ecs-service"
 cluster         = aws_ecs_cluster.prod-ecs-cluster-03.id
 task_definition = aws_ecs_task_definition.ecs_task_definition.arn
 desired_count   = 2

 network_configuration {
   subnets         = [aws_subnet.prod-subnet-public-03-1.id, aws_subnet.prod-subnet-public-03-2.id]
   security_groups = [aws_security_group.security_group.id]
 }

 force_new_deployment = true
 placement_constraints {
   type = "distinctInstance"
 }

 triggers = {
   redeployment = timestamp()
 }

 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
   weight            = 100
 }

 # Here is where service gets linked to load balancer 
 load_balancer {
   target_group_arn = aws_lb_target_group.ecs_tg.arn
   container_name   = "helloWorld"
   container_port   = 80
 }

 depends_on = [aws_autoscaling_group.ecs_asg]
}