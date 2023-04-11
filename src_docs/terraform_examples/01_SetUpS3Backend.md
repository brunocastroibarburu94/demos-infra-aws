# Example 01: Set Up S3 Backend #

This is a trivial but fundamental example, when managing cloud infrastructure you may always want to have access to the current state of your build, even if you are working from another machine and even more important if you are working as part of a team.<br>

In this example S3 will be used to store the terraform state files, **follow up examples will make us of this so make sure of having it done**, albeit is listed among terraform examples this is in fact written in **bash** and the verification is done by initializing terraform with this backend and creating a table that will allow us to lock the state files using DynamoDB.

Imporant note: S3 is a free tier product **(for 12 months)**, on the free tier we will have up to 5Gb of storage free of charge. 

### Acknowledgements

This example follows the [article in Medium written by Francesco Cosentino](https://medium.com/faun/terraform-remote-backend-demystified-cb4132b95057).<br>

### Procedure
Refresh your token if needed.
```bash
. refreshEnv.sh
```

**(One Off Preliminaries):** If needed create the bucket and a terraform user.
```bash 
make tf01_prelim
```

Initialize terraform and setup the backend file for this example.
```bash 
make XX=01 tf_init
```
Then proceed to visualize the resources to be created (since is the first time the state lock table is created we need to bypass the check, just for this example and the first time is run)
```bash 
make XX=01 tf_plan_unlocked # (First time)
make XX=01 tf_plan # (Rest of the times and moving forward)
```
And proceed to create them:
```bash 
make XX=01 tf_apply_unlocked # (First time)
make XX=01 tf_apply # (Rest of the times and moving forward)
```
**Remember to destroy the resources after you finished or you may be charged by AWS.**
```bash 
make XX=01 tf_destroy
```
> This should be relatively cheap (free in most cases) however small charges in the order of pennies per month may apply for storing the state file in S3.

### Description of prelimiary steps
Basically there are 4 steps into setting up S3 as Terraform backend in AWS:<br>

1. Creating the S3 bucket<br>
2. Encrypt the bucket (This example uses AES256, but KMS and key rotation is recommended)<br>
3. **Restrict the access to the bucket**: Create an unpriviledged user and give access to S3 and DynamoDB to this user (this example gives full access for simplicity, is recommended to just give less power to this user).<br>
4. Enforce the policy in the bucket. <br>

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
