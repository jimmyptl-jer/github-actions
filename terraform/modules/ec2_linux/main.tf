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

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",

      # Install Docker
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce",

      # Install Docker Compose
      "sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",

      # Create docker-compose.yml file
      "echo 'version: \"3.8\"\nservices:\n  client:\n    build:\n      context: ./frontend\n      dockerfile: Dockerfile\n    ports:\n      - \"80:80\"\n    networks:\n      - app-network\n  api:\n    build:\n      context: ./backend\n      dockerfile: Dockerfile\n    ports:\n      - \"3000:3000\"\n    networks:\n      - app-network\nnetworks:\n  app-network:' > ~/docker-compose.yml",

      # Run Docker Compose to start containers
      "sudo docker-compose -f ~/docker-compose.yml up -d"
    ]
  }
}
