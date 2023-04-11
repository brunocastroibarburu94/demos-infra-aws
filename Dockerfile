FROM ubuntu:20.04
RUN apt-get update 

# Temporary folder (for installations)
WORKDIR /temp

####################################
###### Terraform Installation ######
####################################
# Install installation dependencies
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

##################################################################################
###### Install Custom Python and dependencies to build MKdocs Documentation ######
##################################################################################
# Add Repository Reference
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
# Get Python from added repository
RUN apt install -y python3.11 python3.11-distutils
# Install pip
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 
# Install Pip-tools for Python3.11
RUN python3.11 -m pip install pip-tools
#Install Requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

#####################################################
###### Setup Container Instantiation Behaviour ######
#####################################################

# Setup Work environment
RUN apt-get install -y make gettext-base jq
WORKDIR /root/project

ENTRYPOINT ["tail", "-f", "/dev/null"]