# Bash Examples: Pushing Images to ECR
In this example we are going to build and push a docker image into ECR, we have a bunch of images we could push including:

- A `Hello World Site`
- A `Streamlit Application`


### Pre-requisites
- Have GitBash console available in your system (recommended)
- Have Docker CLI in your system
- Have AWS CLI in your system
- Set up ECR following [Terraform example 3](/terraform_examples/03_ECR/)
- (Optional) Set up ECS following [Terraform example 4](/terraform_examples/04_ECS/)


### Procedure
This example is a little different from the rest as it is not carried out from the local docker container. 

In this example we are going to build and push a docker image into ECR, if we wanted to do it from the local docker container we would need to either mount the docker socket which bring some cyber security issues [as per Docker documentation](https://docs.docker.com/desktop/hardened-desktop/enhanced-container-isolation/config/) or use Docker-in-Docker approach which presents its own risks.

Therefore for the sake of simplicity this example is to be carried out in a Git Bash console within your system. Moreover we won't be making use of the Makefile for this example.

Before getting started with any of the example make sure of having the following environment variables defined. 
```bash
export AWS_ACCOUNT=012345678910
export REGION=eu-west-1
export ERC_REPO_NAME=prod-ecr-repo
```

#### Hello World Site
On a console of your system (not the docker container) build and push your image into ECR.
```bash 
# Navigate to the images folder
cd ./aws_bash/example_02/hello_world/

# Build your image
docker build -t hello-world .

# (Optional) Run your image locally (to check it works, in your browser go to localhost:80)
docker run -t -i -p 80:80 hello-world

# Tag your image: Images tagged with ${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/prod-ecr-repo are the only ones to be uploaded
docker tag hello-world ${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${ERC_REPO_NAME}

# Link docker to your ECR repository
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${ERC_REPO_NAME}

# (Optional) Test image to be pushed
docker run -p 80:80  ${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/prod-ecr-repo:latest

# Push to ECR
docker push ${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${ERC_REPO_NAME}:latest
```

#### Streamlit App
This example is adapted from the repository [streamlit-example](https://github.com/streamlit/streamlit-example) from the Streamlit team.
```bash

# From the top directory navigate to the folder containing the streamlit app files.
cd ./aws_bash/example_02/streamlit_app/

# Build the image
docker build  -t streamlit-app-image .

# (Optional) Test your app locally
docker run -p 80:80 streamlit-app-image

# Link docker to your ECR repository
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/prod-ecr-repo

# Tag the image
docker tag streamlit-app-image ${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/prod-ecr-repo

# (Optional) Test image to be pushed
docker run -p 80:80  ${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/prod-ecr-repo:latest

# Push to ECR
docker push ${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${ERC_REPO_NAME}:latest

# (Optional) Return to top directory
cd ../../../
```

The size of the image in ECR should be around 442.26 MB, don't worry if the image is larger locally when uploading to ECR the image size reduces for reasons beyond my present knowledge.

## Running the container in EC2
If you have an EC2 instance you canuse and is correctly configured [see how to make it work in Terraform example 4](/terraform_examples/04_ECS/#how-to-make-it-work) you can SSH into the EC2 instance, pull the 

SSH into an EC2 instance and run the following

```bash
export REGION=eu-west-1
export AWS_ACCOUNT=012345678910
export ECR_TARGET=${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/prod-ecr-repo

# (Optional) Check the container
aws sts get-caller-identity

# Authenticate with ECR through a temporary token
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_TARGET}

# Pull Image from ECR
docker pull ${ECR_TARGET}:latest

# Run image
docker run -d -p 80:80 ${ECR_TARGET}
```