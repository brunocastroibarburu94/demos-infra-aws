resource "aws_kms_key" "db_encryption_key" {
  description = "KMS Key"
}

resource "aws_db_subnet_group" "db_subnet_group_05" {
  name       = "db_subnet_group_05"
  subnet_ids = [
    aws_subnet.prod-subnet-public-05-1.id,
    aws_subnet.prod-subnet-public-05-2.id
    ]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_db_parameter_group" "db_parameter_group_05" {
  name   = "my-pg-05"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_db_instance" "postgres_db_05" {
  allocated_storage             = 10
  identifier = "postgres-db-05"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group_05.name
  db_name                       = "postgres05"
  engine                        = "postgres"
  engine_version                = "15"
  instance_class                = "db.t3.small"
  master_user_secret_kms_key_id = aws_kms_key.db_encryption_key.key_id
  vpc_security_group_ids = [aws_security_group.security_group.id]
  parameter_group_name          = aws_db_parameter_group.db_parameter_group_05.name_prefix
  publicly_accessible = true
  username = "bruno"
  manage_master_user_password = true 
}

output "db_identifier" {
  value = aws_db_instance.postgres_db_05.identifier
}

output "db_manage_master_user_password" {
  value = aws_db_instance.postgres_db_05.master_user_secret
}