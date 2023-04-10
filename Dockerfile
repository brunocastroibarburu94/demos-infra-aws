FROM ubuntu:20.04
RUN apt-get update 

# Temporary folder (for installations)
WORKDIR /temp

####################################
###### Terraform Installation ######
####################################
# Install installation dependencies
# RUN apt-get install -y gnupg software-properties-common # Official recommendations are excessive
RUN apt-get install -y wget gpg lsb-release unzip

# Install the HashiCorp GPG key.
RUN wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor |  tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Verify the key's fingerprint.
RUN gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint

# Download Package information
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# Update repositories
RUN apt update

# Install Terraform from the new repository.
RUN apt-get install -y terraform
# Verify installation
RUN terraform --version

##################################
###### AWS CLI Installation ######
##################################
# Installation dependencies
RUN apt-get install -y curl unzip
# Download files
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# Unzip
RUN unzip awscliv2.zip
# Install
RUN ./aws/install
# Verify installation
RUN aws --version

# Setup Work environment
RUN apt-get install -y make
WORKDIR /root/project

ENTRYPOINT ["tail", "-f", "/dev/null"]