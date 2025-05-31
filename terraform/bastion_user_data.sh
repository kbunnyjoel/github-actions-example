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

echo "INFO: Installing kubectl..."
curl -LO "https://dl.k8s.io/release/v1.29.2/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/ # User data runs as root, sudo is for clarity

echo "INFO: Installing unzip and AWS CLI v2..."
yum install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip # -o to overwrite without prompting if it exists
sudo ./aws/install
rm -rf awscliv2.zip aws # Clean up installation files

echo "INFO: Tool installation complete."

# Create an enhanced diagnostic script for the ec2-user
echo "INFO: Creating diagnostic script /home/ec2-user/check_bastion_setup.sh..."
cat << 'EOF' > /home/ec2-user/check_bastion_setup.sh
#!/bin/bash
echo "--- Bastion Setup Diagnostic ---"
echo "Date: $(date)"
echo ""
echo "== SSH Server Status =="
sudo systemctl status sshd --no-pager || echo "Error: Failed to get sshd status"
echo ""
echo "SSH server configuration:"
sudo grep -v "^#" /etc/ssh/sshd_config | grep -v "^$"
echo "SSH listening ports:"
sudo ss -tulpn | grep ssh
echo "Authorized keys:"
ls -la ~/.ssh/
cat ~/.ssh/authorized_keys || echo "Warning: No authorized keys found or readable in ~/.ssh/"
echo ""
echo "== Kubectl Status =="
if command -v kubectl &> /dev/null; then
    kubectl version --client --output=yaml
else
    echo "Error: kubectl command not found!"
fi
echo ""
echo "== AWS CLI Status =="
if command -v aws &> /dev/null; then
    aws --version
else
    echo "Error: AWS CLI command not found!"
fi
echo ""
echo "Public IP:"
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
sudo cat /var/log/cloud-init-output.log
EOF

chmod +x /home/ec2-user/check_bastion_setup.sh
chown ec2-user:ec2-user /home/ec2-user/check_bastion_setup.sh # Ensure ec2-user can execute it
echo "INFO: Diagnostic script created. SSH into the bastion and run: /home/ec2-user/check_bastion_setup.sh"


# Configure kubectl for the EKS cluster
echo "INFO: Configuring kubectl for EKS cluster..."
aws eks update-kubeconfig --region ${aws_region} --name ${cluster_name}

# Add helper function to access ArgoCD
cat << 'EOF' >> /home/ec2-user/.bashrc
# Kubernetes aliases
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgi='kubectl get ingress'

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

# Print welcome message
echo ""
echo "Welcome to the EKS bastion host!"
echo "Run 'argocd_url' to get the ArgoCD URL and credentials"
echo ""
EOF

echo "INFO: Bastion host setup complete!"
