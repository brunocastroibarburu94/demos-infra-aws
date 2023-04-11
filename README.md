# README #
This repository contain a series of examples regarding AWS infrastrucutre, all the way to the basics up to deploying applications in a CICD pipeline.

> It is important to note that this repository is not meant to be a good practice on how to structure a Terraform project. It is just a compilation of examples that can be used for inspiration or for demoing purposes.

### Setup ###
To execute this examples there are some pre-requisites to meet:
1. Have an AWS IAM user with programatic access
2. Have a role that this user can assume to conduit Terraform commands through such role

Once you have the 2 things above in the .env file, and you have configured your AWS CLI credentials locally set up the following environment variables.
```bash
SOURCE_AWS_PROFILE="your-aws-profile"
TERRAFORM_ROLE_TO_ASSUME="arn:aws:iam::12345678901:role/your-role"
# Convenient for S3 Backend automation through (refreshEnv.sh)
S3_BE_BUCKET="your-s3bucket-for-backend"
S3_BE_REGION="your-region"  
```

The idea is that you are going to have one AWS user, but you may be using several environment or roles with different permissions, this will be regulated at the role level.

### S3 Backend ###
Ideally we will be working with cloud based backend, example_01 guides you on how to set up such backend using AWS CLI. After that, we will be using the cloud backend for the downstream examples (these should be independent from each other).


### General usage ###
When you start working first refresh the token by executing in the console:
```bash
. refreshEnv.sh
```

After that look for the example number *XX* to execute and do the following.
1. Look for the corresponding *tfvars* file to set up the required variables. (Or use the environment variables to set them) 
2. Use the makefile to execute the plan apply and destroy operations:
```bash 
make tfXX_plan
make tfXX_apply
make tfXX_destroy
```

> When executing the *plan* or *apply* make commands the file **backend.tf** of the example is modified this is because the the name of the bucket and state file need to be passed as hardcoded strings in the file, therefore a template file is put in place to replace the backend. Moreover this also introduces some nice features as it allows us to dynamically pick the backend to be used if we want to perform the experiment/example on another backend. 
<!-- 
### Content (AWS CLI) ###
**Done**<br>
- Example 01: Listing AMI's
- Example 02: Authentication 
 
**WIP**<br>
- Example 03: JupyterHub 
**TODO**<br>



### Content (Terraform) ###
**Done**<br>
- Example 01: Set up S3 as Backend for Terraform

- Example 08: Jenkins Server running on EC2 (Not fully automated) 
 
- terraform_local: *Needs README*
- terraform_local: Needs README

**WIP**<br>
- Example 02: AWS Lambda Application
    - Folder needs renaming & backend needs to be set as an S3 bucket
- Example 03: SFTP Server
- Example 04: SFTP Server
    - Readme File needs to be expanded

**TODO**<br>


- Example 04: RDS (MariaDB) Database creation  

- Example 07: RDS (MariaDB) Database creation

- Example 10: SSL/TLS app
- Example 12: Jenkins master with slave builders
- Example 15: Jenkins CICD zero-downtime deployment


### Certifications: ###
https://www.aws.training/Transcript/CompletionCertificateHtml?transcriptid=srgvf8z7qEqL9xHczwdfxw2 -->