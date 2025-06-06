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

# Remove any existing kubectl and aws-iam-authenticator
sudo rm -f /usr/bin/kubectl /usr/local/bin/kubectl /usr/bin/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

# Install kubectl with the exact version matching your EKS cluster
echo "INFO: Installing kubectl..."
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/bin/kubectl

# Install AWS CLI v2
echo "INFO: Installing AWS CLI v2..."
yum install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws

echo "INFO: Installing yq..."
curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

echo "INFO: Tool installation complete."

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
echo "export HOME=/home/ec2-user" >> /home/ec2-user/.bash_profile
echo "source ~/.bashrc" >> /home/ec2-user/.bash_profile


# Wait until kubeconfig files are present before patching
for file in /home/ec2-user/.kube/config /root/.kube/config; do
  timeout=60
  while [ ! -f "$file" ] && [ $timeout -gt 0 ]; do
    echo "Waiting for $file to be created..."
    sleep 1
    timeout=$((timeout - 1))
  done
done
