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

data "aws_vpc" "default" {
    default = true
}

data "aws_subnet" "availabily_zone_a" {
  availability_zone = "eu-west-1a"
}

data "aws_subnet" "availabily_zone_b" {
  availability_zone = "eu-west-1b"
}

#-----------------------------------------
# Define instancias
#-----------------------------------------
resource "aws_instance" "servidor_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.availabily_zone_a.id
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  user_data              = <<-EOF
              #!/bin/bash
              echo "hola mundo desde servidor 1" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  tags = {
    Name = "server-1"
  }
}

resource "aws_instance" "servidor_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.availabily_zone_b.id
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  user_data              = <<-EOF
              #!/bin/bash
              echo "hola mundo desde servidor 2" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  tags = {
    Name = "server-2"
  }
}

resource "aws_security_group" "firewall_egress" {
  name   = "firewall_egrees"
  vpc_id = data.aws_vpc.default.id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "open port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
  }
}

resource "aws_security_group" "my_security_group" {
  name   = "firewall_ingress"
  vpc_id = data.aws_vpc.default.id
  ingress {
   // security_groups = [ aws_security_group.my_security_group_load_balancer.id]
    cidr_blocks = ["0.0.0.0/0"]
    description = "open port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
  }
}

resource "aws_security_group" "my_security_group_load_balancer" {
  name   = "firewall_ingress_load_balancer"
  vpc_id = data.aws_vpc.default.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "open port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "open port 80"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
  }
}

resource "aws_lb" "load_balancer_app" {
  load_balancer_type = "application"
  name               = "load-balancer-app"
  security_groups    = [aws_security_group.my_security_group_load_balancer.id]
  subnets            = [data.aws_subnet.availabily_zone_b.id, data.aws_subnet.availabily_zone_a.id]

}

resource "aws_lb_target_group" "load_balancer_target_app" {
  name = "load-balancer-target-app"
  port = 80
  vpc_id = data.aws_vpc.default.id
  protocol = "HTTP"
  health_check {
    enabled = true
    matcher = "200"
    path = "/"
    port = "8080"
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "attachment_servidor_1" {
  target_group_arn = aws_lb_target_group.load_balancer_target_app.arn
  target_id = aws_instance.servidor_1.id
  port = 8080
}

resource "aws_lb_target_group_attachment" "attachment_servidor_2" {
  target_group_arn = aws_lb_target_group.load_balancer_target_app.arn
  target_id = aws_instance.servidor_2.id
  port = 8080
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer_app.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.load_balancer_target_app.arn
    type = "forward"
  }
}

