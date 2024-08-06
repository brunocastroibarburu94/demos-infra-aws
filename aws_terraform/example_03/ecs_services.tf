resource "aws_ecs_task_definition" "ecs_task_definition" {
 family             = "my-ecs-task"
 network_mode       = "awsvpc"
 execution_role_arn = "arn:aws:iam::311924505883:role/AmazonECSTaskExecutionRolePolicy"
#  aws_iam_role.ecs_task_execution_role.arn 
  #"arn:aws:iam::311924505883:role/AmazonECSTaskExecutionRolePolicy"
 #"arn:aws:iam::311924505883:role/ecsTaskExecutionRole"
 cpu                = 256
 runtime_platform {
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
 }
 container_definitions = jsonencode([
   {
     name      = "dockergs"
     image     = "public.ecr.aws/f9n5f1l7/dgs:latest"
     cpu       = 256
     memory    = 512
     essential = true
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
   container_name   = "dockergs"
   container_port   = 80
 }

 depends_on = [aws_autoscaling_group.ecs_asg]
}