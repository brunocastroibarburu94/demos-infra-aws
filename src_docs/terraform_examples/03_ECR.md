# Example 03: Set up an Elastic Container Repository #
In this example we are going to create an ECR and load it with a docker image, this example is also instrumental to downstream examples relying in containerized applications.

### Pre-requisites ###
- Have Docker CLI in your system
- Have AWS CLI in your system
- Set up your S3 backend following [Example 1](/terraform_examples/01_SetUpS3Backend/)


### Procedure

#### 1 - Build your Infrastructure
Refresh your token if needed.
```bash
. refreshEnv.sh
```

Initialize terraform and setup the backend file for this example.
```bash 
make XX=03 tf_init
```
Then proceed to visualize the resources to be created 
```bash 
make XX=03 tf_plan
```
And proceed to create them:
```bash 
make XX=03 tf_apply
```

#### 2 - Upload (Push) Images to ECR
Follow the [bash example to upload Docker images to ECR](/bash_examples/02_push_streamlit_app_to_ECR).


#### 3 - Clean up
**Remember to destroy the resources after you finished or you may be charged by AWS.**
```bash 
make XX=03 tf_destroy
```


### Results
Once you execute the terraform apply you should be able to see the new repository. 
![Locate EC2 instance](figures/e03_ECR.PNG){#fig:showECR}

And inside it you should see image inside tagged with the tag "latest"
![Locate EC2 instance](figures/e03_ECR_image.PNG){#fig:showECRImage}


### Frequent Questions ###

**How do you manage the tags in ECR?**<br> No idea, TODO.