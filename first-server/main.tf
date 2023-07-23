terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.9.0"
    }
  }
}

provider "aws" {
  region                   = "eu-west-1"
  shared_credentials_files = ["/home/piero/.aws/credentials"]
}


data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "my_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  user_data              = <<-EOF
              #!/bin/bash
              echo "hola mundo" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  tags = {
    Name =  "server-1"
  }
}

resource "aws_security_group" "my_security_group" {
  name = "firewall_ingress"
  vpc_id = data.aws_vpc.default.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "open port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
  }
}
