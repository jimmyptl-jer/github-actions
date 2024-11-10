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

  # Connection details for remote-exec
  connection {
    type        = "ssh"
    user        = "ubuntu"           # Default user for Ubuntu AMIs
    private_key = file("server.pem") # Path to SSH private key
    host        = self.public_ip
  }

  # Provisioner to install Docker and run containers
  provisioner "remote-exec" {
    inline = [
      # Install Docker
      "sudo apt-get update -y",
      "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce",
      "sudo systemctl status docker"

      # Pull Docker images
      "sudo docker login -u 'jerry4699' -p 'Graywolf@4699'",
      "sudo docker pull ${secrets.DOCKER_USERNAME}/bookstore:client-${github_run_number}",
      "sudo docker pull ${secrets.DOCKER_USERNAME}/bookstore:api-${github_run_number}",

      # Stop and remove any existing containers
      "sudo docker stop bookstore-client || true",
      "sudo docker rm bookstore-client || true",
      "sudo docker stop bookstore-api || true",
      "sudo docker rm bookstore-api || true",

      # Run the new containers
      "sudo docker run -d -p 80:80 --name bookstore-client ${secrets.DOCKER_USERNAME}/bookstore:client-${github.run_number}",
      "sudo docker run -d -p 3000:3000 --name bookstore-api ${secrets.DOCKER_USERNAME}/bookstore:api-${github.run_number}"
    ]
  }
}
