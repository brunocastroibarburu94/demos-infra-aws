
# create an IGW (Internet Gateway)
# It enables your vpc to connect to the internet
resource "aws_internet_gateway" "prod-igw" { # Internet Gateway (IGW) 
    vpc_id = aws_vpc.prod-vpc.id
    tags = {
        "Name" : "prod-igw"
    }
}

# create a custom route table for public subnets
# public subnets can reach to the internet by using this
resource "aws_route_table" "prod-public-crt" { #Custom Route Table (CRT)
    vpc_id = aws_vpc.prod-vpc.id
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.prod-igw.id
    }
    
    tags = {
        "Name" : "prod-public-crt"
    }
}

# route table association for the public subnets
resource "aws_route_table_association" "prod-crta-public-subnet-1"{
    subnet_id = aws_subnet.prod-subnet-public-1.id
    route_table_id = aws_route_table.prod-public-crt.id
}

data "http" "secure_public_ip_address" {
  url = "http://ipv4.icanhazip.com"
}
# security group
resource "aws_security_group" "ssh-allowed" {
    vpc_id = aws_vpc.prod-vpc.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"] # The instance needs to be able to have outgoing traffic to everywhere to collect packages to install NGINX in the EC2
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        // This means, all ip address are allowed to ssh ! 
        // Do not do it in the production. 
        // Put your office or home address in it!
        cidr_blocks = ["${chomp(data.http.secure_public_ip_address.response_body)}/32"] #[aws_vpc.prod-vpc.cidr_block]
    }
    //If you do not add this rule, you can not reach the NGIX  
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${chomp(data.http.secure_public_ip_address.response_body)}/32"]
    }
    tags =  {
        "Name" : "ssh-allowed"
    }
}