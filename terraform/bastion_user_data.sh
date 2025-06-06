#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Add a section to ensure the SSH server is properly configured
cat << 'EOF' | sudo tee /etc/ssh/sshd_config.d/custom.conf
Port 22
ListenAddress 0.0.0.0
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/libexec/openssh/sftp-server
EOF

# Restart SSH service to apply changes
sudo systemctl restart sshd

# Ensure the SSH key is properly set up
mkdir -p /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
touch /home/ec2-user/.ssh/authorized_keys
chmod 600 /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh

echo "INFO: Starting package updates and tool installation..."

echo "INFO: Running yum update..."
yum update -y

# Install kubectl with the correct version for your EKS cluster
echo "INFO: Installing kubectl..."
curl -LO "https://dl.k8s.io/release/v1.28.5/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/bin/kubectl

# Install AWS CLI v2 with the aws-iam-authenticator
echo "INFO: Installing AWS CLI v2 and aws-iam-authenticator..."
yum install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# Install aws-iam-authenticator
curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.11/aws-iam-authenticator_0.6.11_linux_amd64
chmod +x ./aws-iam-authenticator
sudo mv ./aws-iam-authenticator /usr/bin/aws-iam-authenticator

# Configure kubectl for the EKS cluster
echo "INFO: Configuring kubectl for EKS cluster..."
mkdir -p /home/ec2-user/.kube
aws eks update-kubeconfig --region ap-southeast-2 --name github-actions-eks-example --kubeconfig /home/ec2-user/.kube/config
chown -R ec2-user:ec2-user /home/ec2-user/.kube
chmod 600 /home/ec2-user/.kube/config

# Also configure for root user
aws eks update-kubeconfig --region ap-southeast-2 --name github-actions-eks-example

echo "INFO: Tool installation complete."

# Create a diagnostic script for the ec2-user
# Add Kubernetes aliases
cat << 'EOF' >> /home/ec2-user/.bashrc
# Kubernetes aliases
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get services"
alias kgi="kubectl get ingress"

# ArgoCD helper function
function argocd_url() {
  LB_HOSTNAME=$(kubectl get svc argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  if [ ! -z "$LB_HOSTNAME" ]; then
    echo "ArgoCD URL: http://$LB_HOSTNAME"
    echo "Username: admin"
    echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Password not found")"
  else
    echo "ArgoCD LoadBalancer not found"
  fi
}
EOF

# Source the .bashrc file to make aliases available immediately
echo "source ~/.bashrc" >> /home/ec2-user/.bash_profile
