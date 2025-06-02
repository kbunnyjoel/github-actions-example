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
