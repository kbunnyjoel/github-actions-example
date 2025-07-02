#!/bin/bash
set -xe

# Log to cloud-init
exec > >(tee /var/log/cloud-init-output.log | logger -t user-data) 2>&1

# Update OS packages
yum update -y

# Install unzip, curl, jq
yum install -y curl unzip jq

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws

aws --version

# Set environment variables for future sessions
echo 'export PATH=$PATH:/usr/local/bin:/usr/bin' >> /etc/profile


echo "INFO: Sourcing .bash_profile to load environment variables and aliases"
su - ec2-user -c "source /home/ec2-user/.bash_profile"
