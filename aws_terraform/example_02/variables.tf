variable "aws_region" {    
    default = "eu-west-1"
    type = string
    description = "The region of the AWS account"
}


variable "ami" {
    type = map
    
    default = {
        "eu-west-1" : "ami-09b9e380df60300c8",
        "eu-west-2" : "ami-03dea29b0216a1e03",
        "us-east-1" : "ami-0c2a1acae6667e438"
    }
}

variable "private_key_path" {    
    type = string
    description = "Path to the private SSH key."
    default = "/root/.ssh/demo-e2-key"
}

variable "public_key_path" {
    description = "Path to the public SSH Key."
    default = "/root/.ssh/demo-e2-key.pub"
}

variable "ec2_user" {    
    type = string
    description = "EC2 User."
    default = "ubuntu"
}

