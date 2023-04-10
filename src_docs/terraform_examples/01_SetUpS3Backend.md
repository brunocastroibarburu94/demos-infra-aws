# Example 01: Set Up S3 Backend #

This is a trivial but fundamental example, when managing cloud infrastructure you may always want to have access to the current state of your build, even if you are working from another machine and even more important if you are working as part of a team.<br>

In this example S3 will be used to store the terraform state files, **follow up examples will make us of this so make sure of having it done**, albeit is listed among terraform examples this is in fact written in **bash** and the verification is done by initializing terraform with this backend.

Imporant note: S3 is a free tier product **(for 12 months)**, on the free tier we will have up to 5Gb of storage free of charge. 

### Acknowledgements

This example follows the [article in Medium written by Francesco Cosentino](https://medium.com/faun/terraform-remote-backend-demystified-cb4132b95057).<br>

### Example description
Basically there are 4 steps into setting up S3 as Terraform backend in AWS:
1. Creating the S3 bucket
2. Encrypt the bucket (This example uses AES256, but KMS and key rotation is recommended)
3. Restrict the access to the bucket:
  1. Create an unpriviledged user
  2. Give access to S3 and DynamoDB to this user (this example gives full access for simplicity, is recommended to just give less power to this user.)
4. Enforce the policy in the bucket. 
5. (Optional-Recommended): Lock the s3 bucket to prevent it to be modified/deleted by other users

**Policy file format (policy.json):**
```json
{
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "<ARN of USER>"
            },
            "Action": "s3:*",
            "Resource": "<ARN of bucket>"
        }
    ]
}
```

**Testing that everything went alright:**<br>
Write a terraform with the following code in it:
```terraform
terraform {  
    backend "s3" {
        bucket = "<your-bucket-name>"
        encrypt        = true
        key    = "terraform.tfstate"    
        region = "<your-region>"  
        dynamodb_table = "terraform-state-lock-dynamo"
    }
}

provider "aws" {
  region = var.region
  shared_credentials_file = var.shared_credentials_file
  profile = var.aws_profile
  version = "~> 3.12.0"
}
```
Run the following command
```bash
terraform init
```

**First time running Terraform:**<br>

There are some nuances when running terraform for the first time, this is because the terraform state file doesn't exist nor the dynamoDB table. Therefore you need to bypass the lock (just the first time). 

This bypassing should only be done the first time, the lock is important for users/developers not to write the state file simultaneously. 
```bash
terraform apply -lock=false
```
