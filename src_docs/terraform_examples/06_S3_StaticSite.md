# Example 06: Creating an S3 hosted static website
In this example we will create a static website hosted in S3.
 
### Pre-requisites
- Have Docker CLI in your system
- Set up your S3 backend following [Example 1](/terraform_examples/01_SetUpS3Backend/)

### Procedure
#### 1 - Build your Infrastructure
Refresh your token if needed.
```bash
. refreshEnv.sh
```

Initialize terraform and setup the backend file for this example.
```bash 
make XX=06 tf_init
```
Then proceed to visualize the resources to be created 
```bash 
make XX=06 tf_plan
```
And proceed to create them:
```bash 
make XX=06 tf_apply_plan
```

#### 2 - Create documentation and upload to S3
- []()
```bash

make doc-build

aws s3 cp /root/project/site s3://DEST_BUCKET/ --recursive
```
#### 3 - Clean up
**Remember to destroy the resources after you finished or you may be charged by AWS.**
```bash 
make XX=05 tf_destroy
```


# Related Links
- [Terraform Resource: aws_s3_bucket_website_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration)
- [Terraform Resource: aws_s3_bucket_website_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration)