# Latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------------- Key Pair ----------------
# create_key_pair = true: Terraform generates an ED25519 key, registers it as
# <name>-key and writes the private key to <private_key_output_dir>/<name>-key.pem.
# The private key is also stored in state.
resource "tls_private_key" "ssh" {
  count     = var.create_key_pair ? 1 : 0
  algorithm = "ED25519"
}

resource "aws_key_pair" "generated" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.name}-key"
  public_key = tls_private_key.ssh[0].public_key_openssh

  tags = {
    Name = "${var.name}-key"
  }
}

resource "local_sensitive_file" "private_key" {
  count           = var.create_key_pair ? 1 : 0
  content         = tls_private_key.ssh[0].private_key_openssh
  filename        = "${var.private_key_output_dir}/${var.name}-key.pem"
  file_permission = "0400"
}

# create_key_pair = false: look the key up so a typo fails at plan time.
data "aws_key_pair" "existing" {
  count    = var.create_key_pair ? 0 : 1
  key_name = var.existing_key_name
}

locals {
  key_name         = var.create_key_pair ? aws_key_pair.generated[0].key_name : data.aws_key_pair.existing[0].key_name
  private_key_path = var.create_key_pair ? local_sensitive_file.private_key[0].filename : var.existing_private_key_path
  private_key      = var.create_key_pair ? tls_private_key.ssh[0].private_key_openssh : file(var.existing_private_key_path)
}

# ---------------- EC2 Instances ----------------
# No user_data: configuration is done by the terraform_data resources below,
# so config changes never touch the instances. The AMI comes from a "latest"
# SSM parameter; it is ignored so a new AL2023 release doesn't force a
# replacement either.
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.web_subnet_id
  vpc_security_group_ids      = [var.web_sg_id]
  associate_public_ip_address = true
  key_name                    = local.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.name}-web"
  }
}

resource "aws_instance" "redis" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.redis_subnet_id
  vpc_security_group_ids      = [var.redis_sg_id]
  associate_public_ip_address = false
  key_name                    = local.key_name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.name}-redis"
  }
}

# ---------------- Instance configuration (provisioners) ----------------
# When a setup script changes, only the terraform_data resource is replaced:
# the provisioner re-runs over SSH against the existing instance. The scripts
# are idempotent, so re-running them is safe. Terraform connects from wherever
# `terraform apply` runs, so that IP must be allowed by allowed_ssh_cidr.

locals {
  redis_setup_script = file("${path.module}/templates/redis_setup.sh")
  web_setup_script = templatefile("${path.module}/templates/web_setup.sh.tftpl", {
    redis_host         = aws_instance.redis.private_ip
    redis_port         = var.redis_port
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

  # Not a trigger: only makes the setup wait for the private route to the
  # package repos (NAT and/or S3 endpoint).
  input = var.private_egress_ids

  connection {
    type        = "ssh"
    host        = aws_instance.redis.private_ip
    user        = "ec2-user"
    private_key = local.private_key

    bastion_host        = aws_instance.web.public_ip
    bastion_user        = "ec2-user"
    bastion_private_key = local.private_key
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
    private_key = local.private_key
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
