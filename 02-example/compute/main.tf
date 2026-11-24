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

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  # Configuration is done by terraform_data.web_setup (provisioners), not
  # user_data, so config changes never touch the instance. The AMI comes from
  # a "latest" SSM parameter; ignore it so a new AL2023 release doesn't force
  # a replacement either.
  lifecycle {
    ignore_changes = [ami]
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

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  # Configured by terraform_data.redis_setup; see the web instance note.
  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.project_name}-redis"
  }
}

# ---------------- Instance configuration (provisioners) ----------------
# Provisioners live on terraform_data rather than the instances. When a setup
# script changes, only this resource is replaced: the provisioner re-runs over
# SSH against the existing instance, and the instance itself is left alone.
# The scripts are idempotent, so re-running them is safe.
#
# Terraform connects from wherever you run `terraform apply`, so your IP must
# be allowed by var.allowed_ssh_cidr.

locals {
  redis_setup_script = file("${path.module}/templates/redis_setup.sh")
  web_setup_script = templatefile("${path.module}/templates/web_setup.sh.tftpl", {
    redis_host         = aws_instance.redis.private_ip
    redis_port         = 6379
    app_port           = var.app_port
    redis_check_script = file("${path.module}/scripts/redis_check.py")
  })
}

# Redis has no public IP, so Terraform reaches it through the web instance.
resource "terraform_data" "redis_setup" {
  triggers_replace = {
    instance_id = aws_instance.redis.id
    script_hash = sha256(local.redis_setup_script)
  }

  connection {
    type        = "ssh"
    host        = aws_instance.redis.private_ip
    user        = "ec2-user"
    private_key = tls_private_key.ssh.private_key_openssh

    bastion_host        = aws_instance.web.public_ip
    bastion_user        = "ec2-user"
    bastion_private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "file" {
    content     = local.redis_setup_script
    destination = "/tmp/redis_setup.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo bash /tmp/redis_setup.sh"]
  }
}

# Installs nginx plus a Python app (/opt/redis-check/redis_check.py) that
# connects to Redis over its private IP; nginx proxies / to it.
resource "terraform_data" "web_setup" {
  triggers_replace = {
    instance_id = aws_instance.web.id
    script_hash = sha256(local.web_setup_script)
  }

  connection {
    type        = "ssh"
    host        = aws_instance.web.public_ip
    user        = "ec2-user"
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "file" {
    content     = local.web_setup_script
    destination = "/tmp/web_setup.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo bash /tmp/web_setup.sh"]
  }

  # Configure Redis first so the app can connect as soon as it starts.
  depends_on = [terraform_data.redis_setup]
}
