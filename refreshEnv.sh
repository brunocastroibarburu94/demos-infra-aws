export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
$(aws sts assume-role \
--profile=$SOURCE_AWS_PROFILE \
--role-arn $TERRAFORM_ROLE_TO_ASSUME \
--role-session-name terraformExample \
--query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
--output text))