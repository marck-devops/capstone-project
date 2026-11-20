# ---------------- Key Pair ----------------
# Terraform generates the key. The private key is written to
# ./<project>-key.pem (git-ignored) and is also stored in this stack's state.
resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "web" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name = "${var.project_name}-key"
  }
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0400"
}

# ---------------- EC2 Instance ----------------
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = local.instance_subnet_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.web.key_name

  # Installs nginx plus a Python app (/opt/redis-check/redis_check.py) that
  # connects to the Redis instance over its private IP; nginx proxies / to it.
  # user_data only runs on first boot, so changes replace the instance.
  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/web_user_data.sh.tftpl", {
    redis_host         = aws_instance.redis.private_ip
    redis_port         = 6379
    app_port           = var.app_port
    redis_check_script = file("${path.module}/scripts/redis_check.py")
  })

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-web"
  }
}

#---------------- REDIS Instance ----------------
resource "aws_instance" "redis" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = local.redis_subnet_id
  vpc_security_group_ids      = [aws_security_group.redis.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.web.key_name

  user_data = <<-EOT
    #!/bin/bash
    dnf install -y redis6
    # Listen on all interfaces so the web instance can connect.
    # Access is limited by the redis security group (web SG only).
    sed -i -e 's/^bind .*/bind 0.0.0.0/' -e 's/^protected-mode yes/protected-mode no/' /etc/redis6/redis6.conf
    systemctl enable --now redis6
  EOT

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}-redis"
  }
}
