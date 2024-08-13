resource "aws_cloudwatch_log_group" "my_log_group" {
  name = "my_log_group"
  
  tags = {
    Environment = "production"
    Application = "serviceA"
  }
}