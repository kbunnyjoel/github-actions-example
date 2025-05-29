#!/bin/bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Configure kubectl for the EKS cluster
aws eks update-kubeconfig --region ${aws_region} --name ${cluster_name}

# Install k9s (optional nice-to-have Kubernetes UI)
curl -L https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz | tar xz
sudo mv k9s /usr/local/bin/

echo "export KUBECONFIG=~/.kube/config" >> /home/ec2-user/.bashrc
echo "alias k=kubectl" >> /home/ec2-user/.bashrc