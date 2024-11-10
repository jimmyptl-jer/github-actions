data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu) AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "example" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = "server"
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true

  tags = {
    Name        = var.instance_name
    "Service"   = var.service_name
    "AppTeam"   = var.app_team
    "CreatedBy" = var.createdby
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("server.pem")
    host        = self.public_ip
  }

  # File provisioner to upload the docker-compose.yml to the EC2 instance
  provisioner "file" {
    source      = "${path.module}/../../../docker-compose.yml" # Relative path from ec2_linux directory
    destination = "/home/ubuntu/docker-compose.yml"
  }

  # Remote-exec provisioner to install Docker, Docker Compose and run Docker Compose
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",

      # Install Docker
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce",

      # Install Docker Compose as a plugin
      "sudo apt-get install -y docker-compose-plugin",

      # Ensure Docker Compose plugin is working
      "sudo docker compose version",

      # Run Docker Compose to start containers
      "sudo docker compose -f /home/ubuntu/docker-compose.yml up -d"
    ]
  }
}
