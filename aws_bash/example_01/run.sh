echo "Exporting AMIs into file it_ignored_output_available_amis.json..."
aws ec2 describe-images --owners self amazon > git_ignored_output_available_amis.json;
echo "[Done]"