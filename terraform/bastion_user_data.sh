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

# Set default kubectl version if not provided
if [ -z "${KUBECTL_VERSION}" ]; then
  echo "WARNING: KUBECTL_VERSION environment variable is not set. Using default v1.23.6" >> /var/log/cloud-init-output.log
  KUBECTL_VERSION="v1.23.6"
fi
echo "INFO: Target KUBECTL_VERSION is ${KUBECTL_VERSION}" >> /var/log/cloud-init-output.log


echo "INFO: Running yum update..."
yum update -y

# Remove any existing kubectl and aws-iam-authenticator
sudo rm -f /usr/bin/kubectl /usr/local/bin/kubectl /usr/bin/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

echo "INFO: Installing Helm version ${HELM_VERSION}..."
curl -fsSL -o /tmp/helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar -zxvf /tmp/helm.tar.gz -C /tmp
sudo mv /tmp/linux-amd64/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
helm version

# Ensure /usr/local/bin (where kubectl will be) is in the PATH for the script's execution.
# Prepending ensures it's found first.
export PATH="/usr/local/bin:$PATH"

echo "INFO: Verifying kubectl installation..."
# kubectl was installed to /usr/local/bin/kubectl.
# command -v will search the PATH.
if ! command -v kubectl &>/dev/null; then
  echo "ERROR: kubectl not found in PATH after installation. Expected at /usr/local/bin/kubectl." >> /var/log/cloud-init-output.log
  ls -l /usr/local/bin/kubectl >> /var/log/cloud-init-output.log # Log if file exists, for debugging
  exit 1
fi

if kubectl version --client; then # Use kubectl from PATH
  echo "INFO: kubectl client version check successful." >> /var/log/cloud-init-output.log
else
  echo "ERROR: kubectl version --client failed. The binary might be corrupted or incompatible." >> /var/log/cloud-init-output.log
  exit 1 # Exit if kubectl is installed but not functional
fi

## Check AWS CLI version
aws --version

# Update AWS CLI if needed
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws

# Test AWS CLI authentication with EKS (IAM role permissions)
echo "INFO: Testing AWS CLI authentication with EKS..."
if aws eks get-token --cluster-name github-actions-eks-example --region ap-southeast-2 > /dev/null; then
  echo "INFO: Successfully obtained EKS token. IAM permissions seem okay for get-token." >> /var/log/cloud-init-output.log
else
  echo "WARNING: Failed to obtain EKS token. Check IAM role permissions for the bastion host. This might prevent kubectl from working." >> /var/log/cloud-init-output.log
  # Depending on requirements, you might want to exit here:
  # echo "ERROR: EKS authentication failed, cannot proceed with kubeconfig setup." >> /var/log/cloud-init-output.log
  # exit 1
fi

echo "INFO: Configuring kubectl for EKS cluster github-actions-eks-example..."
# Configure for ec2-user
if aws eks update-kubeconfig --name github-actions-eks-example --region ap-southeast-2 --kubeconfig /home/ec2-user/.kube/config; then
  echo "INFO: kubeconfig updated successfully for ec2-user." >> /var/log/cloud-init-output.log
  chown ec2-user:ec2-user /home/ec2-user/.kube/config
else
  echo "ERROR: Failed to update kubeconfig for ec2-user." >> /var/log/cloud-init-output.log
fi

# Configure for root user
if aws eks update-kubeconfig --name github-actions-eks-example --region ap-southeast-2 --kubeconfig /root/.kube/config; then
  echo "INFO: kubeconfig updated successfully for root." >> /var/log/cloud-init-output.log
else
  echo "ERROR: Failed to update kubeconfig for root." >> /var/log/cloud-init-output.log
fi

echo "INFO: Installing yq..."
curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq


echo "INFO: Tool installation complete."

echo "INFO: Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -o get_helm.sh
chmod +x get_helm.sh
if ./get_helm.sh; then
  echo "INFO: Helm installed successfully"
else
  echo "ERROR: Helm installation failed" >> /var/log/cloud-init-output.log
  exit 1
fi
rm -f get_helm.sh
export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> /home/ec2-user/.bash_profile
if ! command -v helm &>/dev/null; then
  echo "ERROR: helm installation failed" >> /var/log/cloud-init-output.log
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

# Ensure /usr/bin is in the PATH for all users
echo 'export PATH=$PATH:/usr/bin' >> /etc/profile
echo 'export PATH=$PATH:/usr/local/bin' >> /etc/profile
echo 'export PATH=$PATH:/usr/local/bin' >> /home/ec2-user/.bash_profile


# Ensure PATH is updated in .bashrc as well
echo 'export PATH=$PATH:/usr/local/bin:/usr/bin' >> /home/ec2-user/.bashrc

# Ensure PATH is set for root user as well
echo 'export PATH=$PATH:/usr/local/bin:/usr/bin' >> /root/.bashrc
echo 'export PATH=$PATH:/usr/local/bin:/usr/bin' >> /root/.bash_profile

# Validation checks
echo "VALIDATION CHECK"
echo "kubectl location: $(command -v kubectl)"
echo "helm location: $(command -v helm)"
kubectl version --client
helm version

# Create symbolic links in /usr/bin
echo "INFO: Creating symbolic links in /usr/bin..."
sudo ln -sf /usr/local/bin/kubectl /usr/bin/kubectl
sudo ln -sf /usr/local/bin/helm /usr/bin/helm
sudo ln -sf /usr/local/bin/yq /usr/bin/yq

# Make binaries executable
sudo chmod +x /usr/bin/kubectl
sudo chmod +x /usr/bin/helm
sudo chmod +x /usr/bin/yq
sudo chmod +x /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/helm
sudo chmod +x /usr/local/bin/yq

# Create a simple script to install kubectl and helm manually if needed
cat > /home/ec2-user/install-tools.sh << 'EOF'
#!/bin/bash
echo "Installing kubectl and helm manually..."

# Install kubectl
curl -LO "https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/bin/kubectl

# Install helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Tools installed successfully!"
EOF
chmod +x /home/ec2-user/install-tools.sh
chown ec2-user:ec2-user /home/ec2-user/install-tools.sh

# Add a message to .bash_profile to inform the user about the manual installation script
echo "echo 'If kubectl or helm commands are not found, run: ./install-tools.sh'" >> /home/ec2-user/.bash_profile


echo "MARKER: User data script completed at $(date)" >> /var/log/cloud-init-output.log
