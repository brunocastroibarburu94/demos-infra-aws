
terraform {  
    backend "s3" {
        bucket  = "$S3_BE_BUCKET"
        encrypt = true
        key     = "$S3_BE_KEY"
        region  = "$S3_BE_REGION"  
        dynamodb_table = "terraform-state-lock-dynamo"
    }
}

provider "aws" {
  region  = "$S3_BE_REGION"  
}