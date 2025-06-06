# Get your public IP dynamically
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Use Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_route53_zone" "main" {
  name         = "bunnycloud.xyz."
  private_zone = false
}

resource "tls_private_key" "deployment_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployment_key" {
  key_name   = "deployment-key"
  public_key = tls_private_key.deployment_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.deployment_key.private_key_pem
  filename        = "${path.module}/keys/deployment_key.pem"
  file_permission = "0400"
}

# Bastion security group (allow SSH from your IP)
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      format("%s/32", chomp(data.http.my_ip.response_body)),
      "103.224.52.138/32", # Your current IP
      "0.0.0.0/0"          # Allow from any IP (remove this in production)
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bastion EC2 instance in public subnet
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro" # Changed from t3.small to t3.micro
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.deployment_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  user_data = templatefile("${path.module}/bastion_user_data.sh", {
    aws_region   = "ap-southeast-2",
    cluster_name = "github-actions-eks-example"
  })

  root_block_device {
    delete_on_termination = true
    volume_size           = 8
  }

  tags = {
    Name = "bastion-host"
  }
  lifecycle {
    create_before_destroy = true
  }
}



# Allocate and associate an Elastic IP for the bastion
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  # lifecycle {
  #   prevent_destroy = true
  # }
  tags = {
    Name = "bastion-eip"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "bastion_dns" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "bastion"
  type    = "A"
  ttl     = 60 # Reduced TTL for faster propagation
  records = [aws_eip.bastion_eip.public_ip]
}

# Create a kubeconfig file locally
# Update the kubeconfig template
resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name     = var.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
    cluster_ca_data  = module.eks.cluster_certificate_authority_data
    region           = var.aws_region
    account_id       = data.aws_caller_identity.current.account_id
    api_version      = "client.authentication.k8s.io/v1beta1" # Add this line
  })
  filename = "${path.module}/kubeconfig"
}

# Copy kubeconfig to bastion host
resource "null_resource" "copy_kubeconfig" {
  depends_on = [aws_instance.bastion, local_file.kubeconfig, aws_eip.bastion_eip]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for SSH to be available
      echo "Waiting for SSH to become available..."
      for i in {1..30}; do
        if ssh -i ${path.module}/keys/deployment_key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@${aws_eip.bastion_eip.public_ip} "echo SSH is ready"; then
          echo "SSH is ready"
          break
        fi
        echo "Attempt $i: SSH not ready yet, waiting 10 seconds..."
        sleep 10
        if [ $i -eq 30 ]; then
          echo "Timed out waiting for SSH to become available"
          exit 1
        fi
      done
      
      # Copy kubeconfig
      scp -i ${path.module}/keys/deployment_key.pem -o StrictHostKeyChecking=no ${path.module}/kubeconfig ec2-user@${aws_eip.bastion_eip.public_ip}:/home/ec2-user/.kube/config
      ssh -i ${path.module}/keys/deployment_key.pem -o StrictHostKeyChecking=no ec2-user@${aws_eip.bastion_eip.public_ip} "chmod 600 /home/ec2-user/.kube/config && sudo mkdir -p /root/.kube && sudo cp /home/ec2-user/.kube/config /root/.kube/config"
    EOT
  }

  triggers = {
    bastion_id         = aws_instance.bastion.id
    kubeconfig_content = local_file.kubeconfig.content
  }
}
