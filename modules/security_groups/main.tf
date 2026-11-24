# ---------------- Web Security Group ----------------
resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "Allow SSH and HTTP inbound, all outbound"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Python redis-check app"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-web-sg"
  }
}

# ---------------- Redis Security Group ----------------
# Redis has no public IP, so it is only reachable from the web instance:
# Redis traffic from the web tier, and SSH with the web instance as a jump host.
resource "aws_security_group" "redis" {
  name        = "${var.name}-redis-sg"
  description = "Allow Redis and SSH from the web security group, all outbound"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from web"
    from_port       = var.redis_port
    to_port         = var.redis_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description     = "SSH from web (jump host)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-redis-sg"
  }
}
