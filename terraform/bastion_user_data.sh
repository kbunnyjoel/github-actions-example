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
EOF

chmod +x /home/ec2-user/check_bastion_setup.sh
chown ec2-user:ec2-user /home/ec2-user/check_bastion_setup.sh # Ensure ec2-user can execute it
echo "INFO: Diagnostic script created. SSH into the bastion and run: /home/ec2-user/check_bastion_setup.sh"
