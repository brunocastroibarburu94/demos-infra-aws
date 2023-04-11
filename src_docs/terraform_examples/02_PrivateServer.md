# Example 02: VPN and server creation #



In this example we are going to create a VPN and access it only from our current (public) IP address. This tutorial is inspired in the example provided [by AWS in their official documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#nacl-examples). This example also takes advantage of the guidance provided by [Ali Atakan Medium article](https://medium.com/@aliatakan/terraform-create-a-vpc-subnets-and-more-6ef43f0bf4c1).<br>

This implementation makes use of Security Group that acts as a firewall filtering the incoming and outgoing traffic from instances within the subnet within the VPC. There's  a second way of doing this (in example 3) that uses ACL's. 

### Pre-requisites ###
**SSH keys:** As part of this example a server in EC2 will be created, and access to it through SSH will be granted from your public IP.  The default key pair will be *demo-e2-key* and demo-e2-key.pub. Which will be stored under **/root/.ssh/**.<br>

You can use the following command to generate the key pair.

```bash
ssh-keygen -f /root/.ssh/demo-e2-key
```

Then you can use the following command to connect via SSH once the server is up:

```bash
ssh -i ireland-region-key-pair ubuntu@ec2-34-243-2-176.eu-west-1.compute.amazonaws.com
```

<!-- 
### Installation steps ###

0. Declare the variables that you are going to use in this example in the **variables.tf** file: 
```golang
variable "aws_region" {    
    default = "eu-west-1"
    type = string
    description = "The region of the AWS account"
}

variable "secure_public_ip_address" {    
    type = string
    description = "The ip address (IPv4) that can access the instance"
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
    description = "Path to the private Key of the SSH."
    default = "ireland-region-key-pair"
}

variable "public_key_path" {
  default = "ireland-region-key-pair.pub"
}

variable "ec2_user" {    
    type = string
    description = "EC2 User."
    default = "ubuntu"
}
```

1. Define the providers used for this example in the **providers.tf** file:

```golang
provider "aws" {
    region = var.aws_region
    version = "~> 3.14.1"
}
```


2. Create the VPC and the Subnet in the file **vpc.tf**:

```golang
resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true #gives you an internal domain name
    enable_dns_hostnames = true #gives you an internal host name
    enable_classiclink = false
    instance_tenancy = "default"    
    
    tags = {
        "Name" : "prod-vpc"
    }
}

resource "aws_subnet" "prod-subnet-public-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "eu-west-1a"
    tags = {
        "Name" : "prod-subnet-public-1"
    }
}
``` 

3. In the file **network.tf**: Create the Internet Gateway that will allow the VPC to connect to the internet, define the IP addresses that the VPC can access/be accessed with through the Custom Route Table and associate it with the Subnet created before. Lastly define the Security Group that will act as the firewall of the instance.
```golang

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
        cidr_blocks = ["${var.secure_public_ip_address}/32"] #[aws_vpc.prod-vpc.cidr_block]
    }
    //If you do not add this rule, you can not reach the NGIX  
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.secure_public_ip_address}/32"]
    }
    tags =  {
        "Name" : "ssh-allowed"
    }
}
```

5.  In the **ec2.tf** define the EC2 as belonging in the previously defined subnet and associate with it the previously defined security group (firewall). Also associate a SSH key with it (to be created in the next step), and indicate to the instance that it needs to execute the file **nginx.sh** when instantiated, this file will install and trigger the NGINX server.

```golang
resource "aws_instance" "web1" {
    ami = lookup(var.ami, var.aws_region)
    instance_type = "t2.micro"
    # VPC
    subnet_id = aws_subnet.prod-subnet-public-1.id
    # Security Group
    vpc_security_group_ids = [aws_security_group.ssh-allowed.id]
    # the Public SSH key
    key_name = aws_key_pair.ireland-region-key-pair.id
    # nginx installation
    provisioner "file" {
        source = "nginx.sh"
        destination = "/tmp/nginx.sh"
    }
    provisioner "remote-exec" {
        inline = [
             "chmod +x /tmp/nginx.sh",
             "sudo /tmp/nginx.sh"
        ]
    }
    connection {
        host = self.public_ip
        user = var.ec2_user
        private_key = file(var.private_key_path)
    }
}
// Sends your public key to the instance
resource "aws_key_pair" "ireland-region-key-pair" {
    key_name = "ireland-region-key-pair"
    public_key = file(var.public_key_path)
}
```

However looking deeper two **provisioner** resources are being used. <br>

First the **file** provisioner is used to copy files or directories from the machine executing Terraform to the newly created resource, the file provisioner supports both ssh and winrm type connections.<br>

Secondly the **remote-exec** provisioner invokes a script on a remote resource after it is created ([Terraform Docs](https://www.terraform.io/docs/language/resources/provisioners/remote-exec.html)). Which in this case is used to change the **nginx.sh** file making it executable and immediately after execute it, triggerring the installation of NGINX server in the ec2 instance.<br>

For the provider to connect to the EC2 instance and run the script we need to provide it with a connection block (either for all provisioners, if nested within the resource, or to a specific provisioner if decalred within the provisioner, [Terraform Docs](https://www.terraform.io/docs/language/resources/provisioners/connection.html)).
-  **host** - (Required) The address of the resource to connect to.(For example, use self.public_ip to reference an aws_instance's public_ip attribute)
-  **user** - The user that we should use for the connection.
-  **private_key** - The contents of an SSH key to use for the connection. These can be loaded from a file on disk using the file function. 

6. Congrats! The Terraform code is all done, however we need to generate the keypair to be able to SSH into the EC2 instance which can be done with following CLI command. 

```bash
#!/usr/bin/env bash
ssh-keygen -f ireland-region-key-pair
```
And also you need to create a file called **nginx.sh** that contains the command to install the NGINX server in the EC2 instance and initialize it once started. The loading/installation of a program through another program is usually called bootstrapping. 

```bash
#!/bin/bash

# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# install nginx
sudo apt install root-system-bin

sudo apt-get update
sudo apt-get -y install nginx

# make sure nginx is started
sudo service nginx start
```

7. All that remains to do before running terraform is to create the **variables.tfvar** file defining your particular zone and public IP address.

```golang 
aws_region = "eu-west-1"

secure_public_ip_address = "1.2.3.4"
```

8.  is all done now, feel free to

```bash
#!/bin/bash

terraform init

terraform apply -var-file=variables.tfvars
```

### Rants: ###
**Security Groups vs Access Control Lists (ACL)**<br>
Security group is the firewall of EC2 Instances whereas Network ACL is the firewall of the Subnet.

- ACL works like a global firewall for the VPC
- Security groups works like a firewalls for the instances

### On Security Groups ###

**Security group rules**<br>

- A rule applies either to inbound traffic (**ingress**) or outbound traffic (**egress**). 


**What do I put in the CIDR block?** <br>
Well well well, what you need to do is to put your public IP address followed by a "/" slash 32. This is because of the notation used for CIDR, where you indicate how many bits are used to identify the network protion of the address. For more info look into [This WEBSITE](https://docs.netgate.com/pfsense/en/latest/network/cidr.html) and [This WEBSITE](https://docs.netgate.com/pfsense/en/latest/network/cidr.html).


### Implementation Notes ###

The **nginx.sh** file contains the set of commands that the EC2 instance is going to run once created, basically it will fetch the libraries needed to install the nginx server and run it. An important factor to consider is that if you are using Windows the End of Line (EOF) character is different and you will need to change it to the Linux type. Otherwise you are going to see errors like this after the **terraform apply** command:<br>

```bash
aws_instance.web1: Still creating... [40s elapsed]
aws_instance.web1 (remote-exec): /tmp/nginx.sh: 1: /tmp/nginx.sh:
aws_instance.web1 (remote-exec): : not found
aws_instance.web1 (remote-exec): /tmp/nginx.sh: 3: /tmp/nginx.sh:
aws_instance.web1 (remote-exec): : not found
aws_instance.web1 (remote-exec): /tmp/nginx.sh: 19: /tmp/nginx.sh: Syntax error: end of file unexpected (expecting "do")


Error: error executing "/tmp/terraform_1180621267.sh": Process exited with status 2
```

Alternatively you can SSH directly into the instance using:
```bash
ssh -i ireland-region-key-pair ubuntu@ec2-3-250-18-225.eu-west-1.compute.amazonaws.com
```

And install the nginx server manually. 

**Make sure that whenn using Terraform you are using your IP address in the whitelisting rules, otherwise the terraform apply command won't be able to provide the file nginx.sh to the EC2 instance.** -->


### Frequent Questions ###

**How do you know your public IP address?**<br>
However as you may already know if your internet provider allocates you a dynamic IP address, your public IP address is going to change everytime you turn on and off your PC. Therefore the first thing to address in this document is how to retrieve your public IP address thing you need to do is to know what your. <br>


There are many ways to get your public IP address:
1. From Bash Script: As in this  [StackExchange article](https://unix.stackexchange.com/questions/22615/how-can-i-get-my-external-ip-address-in-a-shell-script), using the **dig** command working with [OpenDNS](https://en.wikipedia.org/wiki/OpenDNS).<br>
```bash
dig +short myip.opendns.com @resolver1.opendns.com
```
2. From using your brower and going to [http://ipv4.icanhazip.com](http://ipv4.icanhazip.com). Note that if you are using a VPN this value may change.

In this example we do not care about the passing it as an input because the IP address is fetched using
```go
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
```
