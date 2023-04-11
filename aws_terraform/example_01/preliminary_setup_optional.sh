#!/bin/bash
echo "Set up of S3 bucket as Terraform Backend"

echo "Step 1: Create S3 Bucket..."

aws s3api create-bucket --bucket $S3_BE_BUCKET \
    --region eu-west-1 \
    --object-lock-enabled-for-bucket \
    --create-bucket-configuration \
    LocationConstraint=eu-west-1 
    
echo "Step 2: Encrypt S3 Bucket..."

aws s3api put-bucket-encryption \
    --bucket $S3_BE_BUCKET \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

echo "Step 3.1: Create User"
aws iam create-user --user-name $USER_NAME_TERRAFORM_DEPOLYER > git_ignored_output_user_details.json

echo "Step 3.2: Grant S3 privileges to User"
aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --user-name $USER_NAME_TERRAFORM_DEPOLYER

echo "Step 3.2: Grant DynamoDB privileges to User"
aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess --user-name $USER_NAME_TERRAFORM_DEPOLYER


echo "Finished to proceed to Step 4 remember to create the policy.json file as presented in the Readme File."
echo "git_ignored_output_user_details.json should contain the new user ARN."

echo "Step 4: Implementing Policy in Bucket"

envsubst < template_policy.json > git_ignored_output_policy.json

aws s3api put-bucket-policy --bucket $S3_BE_BUCKET --policy file://git_ignored_output_policy.json