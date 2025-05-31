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

# Add a script to check SSH connectivity
cat << 'EOF' > /home/ec2-user/check_ssh.sh
#!/bin/bash
echo "SSH server status:"
sudo systemctl status sshd

yum update -y
curl -LO "https://dl.k8s.io/release/v1.29.2/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
yum install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && ./aws/install

echo "SSH server configuration:"
sudo grep -v "^#" /etc/ssh/sshd_config | grep -v "^$"

echo "SSH listening ports:"
sudo ss -tulpn | grep ssh

echo "Authorized keys:"
ls -la ~/.ssh/
cat ~/.ssh/authorized_keys

echo "Public IP:"
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
EOF

chmod +x /home/ec2-user/check_ssh.sh
