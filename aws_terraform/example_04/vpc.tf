resource "aws_vpc" "prod-vpc-03" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true #gives you an internal domain name
    enable_dns_hostnames = true #gives you an internal host name
    instance_tenancy = "default"    
    
    tags = {
        "Name" : "prod-vpc-03"
    }
}

resource "aws_subnet" "prod-subnet-public-03-1" {
    vpc_id = aws_vpc.prod-vpc-03.id
    cidr_block = cidrsubnet(aws_vpc.prod-vpc-03.cidr_block, 8, 1) # dynamically calculate the CIDR range based on the VPC’s CIDR.
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "eu-west-1a"
    tags = {
        "Name" : "prod-subnet-public-03-1"
    }
}

resource "aws_subnet" "prod-subnet-public-03-2" {
    vpc_id = aws_vpc.prod-vpc-03.id
    cidr_block = cidrsubnet(aws_vpc.prod-vpc-03.cidr_block, 8, 2) # dynamically calculate the CIDR range based on the VPC’s CIDR.
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "eu-west-1b"
    tags = {
        "Name" : "prod-subnet-public-03-2"
    }
}

# This route table enables internet communication of both the subnets, making them public.
resource "aws_internet_gateway" "internet_gateway" {
 vpc_id = aws_vpc.prod-vpc-03.id
 tags = {
   Name = "internet_gateway"
 }
}

resource "aws_route_table" "route_table" {
 vpc_id = aws_vpc.prod-vpc-03.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.internet_gateway.id
 }
}

resource "aws_route_table_association" "subnet_route" {
 subnet_id      = aws_subnet.prod-subnet-public-03-1.id
 route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet2_route" {
 subnet_id      = aws_subnet.prod-subnet-public-03-2.id
 route_table_id = aws_route_table.route_table.id
}

# Create a security group along with ingress and egress rules
# Both ingress and egress rules of the security group allow inbound and outbound 
# access for any protocol, via any port. This is not the best practice and should 
# only be done for working through this example. Tighter rules should be implemented 
# when in production.

resource "aws_security_group" "security_group" {
 name   = "ecs-security-group"
 vpc_id = aws_vpc.prod-vpc-03.id

 ingress {
   from_port   = 0
   to_port     = 0
   protocol    = -1
   self        = "false"
   cidr_blocks = ["0.0.0.0/0"]
   description = "any"
 }

 egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}