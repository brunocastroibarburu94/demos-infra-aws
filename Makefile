

dir_proj := /root/project
# Example1 is important as it has a preliminary step
dir_tf01 := ${dir_proj}/aws_terraform/example_01
# S3 Backend Template
s3bet := ${dir_proj}/templates/TerraformS3Backend.tf
# Directory 
dir_XX := ${dir_proj}/aws_terraform/example_${XX}




pip-compile:
	pip-compile --resolver=backtracking --verbose --output-file=requirements.txt requirements.in
	pip-sync requirements.txt

run:
	echo "Hi"

bash01:
	cd ./aws_bash/example_01_retrieve_available_amis;  ./get_available_amis.sh;

tf01_prelim:
	cd ${dir_tf01} && . preliminary_setup_optional.sh
	
# Generic commands
tf_init:
	cd ${dir_XX} &&	export S3_BE_KEY=tf${XX}/terraform.tfstate; envsubst < ${s3bet} > backend.tf &&	terraform init

tf_plan:
	cd ${dir_XX} &&	terraform plan

tf_apply:
	cd ${dir_XX} &&	terraform apply -auto-approve -lock=false

tf_destroy:
	cd ${dir_XX} &&	terraform destroy

# Sometimes you may want to override the lock (Proceed with care)
tf_plan_unlocked:
	cd ${dir_XX} &&	terraform plan -lock=false

tf_apply_unlocked:
	cd ${dir_XX} &&	terraform apply -lock=false

# Website documentation targets
doc-build:
	mkdocs build

doc-serve:
	mkdocs serve --dev-addr 0.0.0.0:8031 --config-file ./mkdocs.yml --verbose #--quiet #& >/dev/null &