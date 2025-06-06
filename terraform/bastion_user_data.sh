#!/bin/bash
echo "MARKER: User data script started running at $(date)" >> /var/log/cloud-init-output.log
set -e # Exit immediately if a command exits with a non-zero status.


# Ensure the SSH key is properly set up
mkdir -p /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
touch /home/ec2-user/.ssh/authorized_keys
chmod 600 /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh

# Create kubectl config directories early
mkdir -p /home/ec2-user/.kube
mkdir -p /root/.kube
touch /home/ec2-user/.kube/config
touch /root/.kube/config
chown -R ec2-user:ec2-user /home/ec2-user/.kube
chmod 600 /home/ec2-user/.kube/config
chmod 600 /root/.kube/config

echo "INFO: Starting package updates and tool installation..."

echo "INFO: Running yum update..."
yum update -y

# Remove any existing kubectl and aws-iam-authenticator
sudo rm -f /usr/bin/kubectl /usr/local/bin/kubectl /usr/bin/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

echo "INFO: Installing kubectl version ${KUBECTL_VERSION}..."

KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
echo "Downloading from: $KUBECTL_URL"

curl -fLo /tmp/kubectl "$KUBECTL_URL"

if [ ! -s /tmp/kubectl ]; then
  echo "ERROR: kubectl not downloaded correctly."
  exit 1
fi

chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/bin/kubectl

echo "INFO: Verifying kubectl installation..."
if ! command -v kubectl &>/dev/null; then
  echo "ERROR: kubectl not found in PATH after installation."
  exit 1
fi

kubectl version --client || echo "WARNING: kubectl installed but failed to run"

## Check AWS CLI version
aws --version

# Update AWS CLI if needed
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws

# Test AWS CLI authentication with EKS
echo "INFO: Testing AWS CLI authentication with EKS..."
if aws eks get-token --cluster-name github-actions-eks-example --region ap-southeast-2; then
  echo "INFO: Successfully authenticated with EKS cluster"
else
  echo "WARNING: Failed to authenticate with EKS cluster. Check IAM permissions."
fi

echo "INFO: Installing yq..."
curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq


echo "INFO: Tool installation complete."

echo "INFO: Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> /home/ec2-user/.bash_profile
if ! command -v helm &>/dev/null; then
  echo "ERROR: helm installation failed"
  exit 1
fi
helm version

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
echo "export KUBECONFIG=/home/ec2-user/.kube/config" >> /home/ec2-user/.bash_profile
echo "source ~/.bashrc" >> /home/ec2-user/.bash_profile

# Create a script to fix kubectl config on login
cat > /home/ec2-user/fix-kubectl-config.sh << 'EOF'
#!/bin/bash

# Check if kubeconfig exists
if [ -f ~/.kube/config ]; then
  # Check if interactiveMode is missing
  if ! grep -q "interactiveMode" ~/.kube/config; then
    echo "Adding interactiveMode: Never to kubectl config..."
    sed -i '/command: aws/i \      interactiveMode: Never' ~/.kube/config
    echo "kubectl config updated successfully."
  fi
fi
EOF

chmod +x /home/ec2-user/fix-kubectl-config.sh
chown ec2-user:ec2-user /home/ec2-user/fix-kubectl-config.sh

# Add the fix script to .bashrc to run on login
echo "# Fix kubectl config on login" >> /home/ec2-user/.bashrc
echo "~/fix-kubectl-config.sh" >> /home/ec2-user/.bashrc
echo "MARKER: User data script completed at $(date)" >> /var/log/cloud-init-output.log
