terraform {
  required_version = ">= 1.6.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

resource "aws_security_group" "allow_web" {
  name   = "allow_web_traffic"
  description = "Security group for web server traffic and SSH" # תיאור לקבוצה
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow secure outbound web traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow standard outbound web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  
  root_block_device {
    encrypted = true
  }

  user_data = <<-EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo docker run -d -p 80:80 --name web-site nginx
sleep 5
sudo docker exec web-site sh -c "echo '<h1>Liav DevOps Project - Managed by Terraform</h1>' > /usr/share/nginx/html/index.html"
EOF

  tags = { Name = "Liav-DevOps-Server" }
}

output "server_ip" {
  value = aws_instance.web_server.public_ip
}
