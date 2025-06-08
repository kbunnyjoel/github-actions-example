#!/bin/bash
set -xe

# Log to cloud-init
exec > >(tee /var/log/cloud-init-output.log | logger -t user-data) 2>&1

# Update OS packages
yum update -y

# Install unzip, curl, jq
yum install -y curl unzip jq

# Set desired versions from Terraform variables
KUBECTL_VERSION="${KUBECTL_VERSION}"
HELM_VERSION="${HELM_VERSION}"

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws

# Install kubectl
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
if [ ! -f /usr/local/bin/kubectl ]; then
  echo "ERROR: kubectl installation failed"
  exit 1
fi

# Install Helm
curl -Lo helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
if [ ! -f /usr/local/bin/helm ]; then
  echo "ERROR: helm installation failed"
  exit 1
fi
rm -rf helm.tar.gz linux-amd64

# Verify installations
kubectl version --client
helm version
aws --version

#
# Configure kubeconfig and fix deprecated version
su - ec2-user -c "
  mkdir -p ~/.kube && \
  mv ~/.kube/config ~/.kube/config.bk \
  aws eks update-kubeconfig --region ap-southeast-2 --name github-actions-eks-example --kubeconfig ~/.kube/config && \
  sed -i 's|client.authentication.k8s.io/v1alpha1|client.authentication.k8s.io/v1beta1|g' ~/.kube/config
"

# Set environment variables for future sessions
echo 'export PATH=$PATH:/usr/local/bin:/usr/bin' >> /etc/profile
echo 'export KUBECONFIG=/home/ec2-user/.kube/config' >> /home/ec2-user/.bash_profile
echo 'export KUBECONFIG=/home/ec2-user/.kube/config' >> /home/ec2-user/.bashrc

# Add Kubernetes aliases for ec2-user
echo 'alias k="kubectl"' >> /home/ec2-user/.bashrc
echo 'alias kgp="kubectl get pods"' >> /home/ec2-user/.bashrc
echo 'alias kgs="kubectl get services"' >> /home/ec2-user/.bashrc
echo 'alias kgi="kubectl get ingress"' >> /home/ec2-user/.bashrc

echo "INFO: Sourcing .bash_profile to load environment variables and aliases"
su - ec2-user -c "source /home/ec2-user/.bash_profile"
