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

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload your local SSH public key
resource "aws_key_pair" "eks_ssh" {
  key_name   = "eks-ssh-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Save the private key to your local machine
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/deployer-key.pem"
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
    cidr_blocks = [format("%s/32", chomp(data.http.my_ip.response_body))]
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
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.eks_ssh.key_name

  tags = {
    Name = "bastion-host"
  }
}
