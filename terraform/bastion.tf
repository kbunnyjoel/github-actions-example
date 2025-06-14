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
  name        = "bastion-sg"
  description = "Security group for bastion host allowing SSH access from specific IPs"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "${chomp(data.http.my_ip.response_body)}/32", # Your current IP (89.187.162.91/32)
    ]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# Bastion EC2 instance in public subnet
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.deployment_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
  user_data              = templatefile("${path.module}/bastion_user_data.sh", {})

  root_block_device {
    delete_on_termination = true
    volume_size           = 8
    encrypted             = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
  }

  tags = {
    Name = "bastion-host"
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [module.eks]
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
  count   = var.create_dns_records ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "bastion"
  type    = "A"
  ttl     = 60
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
