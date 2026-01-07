provider "aws" {
  region = "us-east-1"
}

# --- 1. NETWORK SETUP (Since you have no default) ---

# Create a Virtual Network (VPC)
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "Playflix-VPC" }
}

# Create an Internet Gateway (So the server can talk to the internet)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}

# Create a Subnet (A slice of the network where the server lives)
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Give it a public IP automatically
  availability_zone       = "us-east-1a"
}

# Create a Route Table (Traffic signs pointing to the internet)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Connect the Route Table to the Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --- 2. SECURITY (Firewall) ---

resource "aws_security_group" "web_sg" {
  name        = "playflix-sg"
  description = "Allow Web and SSH"
  vpc_id      = aws_vpc.main_vpc.id # Link to our new VPC

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 3. SERVER (EC2 Instance) ---

# Automatically find the latest Ubuntu 22.04 Image
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu owner)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "playflix-key"  # <--- MAKE SURE THIS KEY EXISTS IN AWS CONSOLE
  subnet_id     = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "Playflix-Server"
  }
}

output "server_ip" {
  value = aws_instance.app_server.public_ip
}