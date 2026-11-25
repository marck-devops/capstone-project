variable "environment" {
  description = "Environment this var file is for. Must match the selected Terraform workspace, so a var file can't be applied to the wrong state."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "project_name" {
  description = "Name prefix and Project tag for every resource"
  type        = string
  default     = "capstone-ex04"
}

# ---------------- Network ----------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.40.1.0/24", "10.40.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.40.10.0/24", "10.40.20.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for outbound internet from the private subnets. It is billed hourly; with it off, redis still installs packages through the S3 gateway endpoint."
  type        = bool
  default     = false
}

variable "enable_s3_gateway_endpoint" {
  description = "Create a free S3 gateway endpoint so private instances can reach the Amazon Linux 2023 package repos without a NAT gateway"
  type        = bool
  default     = true

  validation {
    condition     = var.enable_nat_gateway || var.enable_s3_gateway_endpoint
    error_message = "With enable_nat_gateway = false, enable_s3_gateway_endpoint must be true or the redis instance cannot install packages."
  }
}

variable "enable_ssm_endpoints" {
  description = "Create ssm / ssmmessages / ec2messages interface endpoints so the private redis instance can reach Session Manager without a NAT gateway (billed hourly per endpoint per AZ)"
  type        = bool
  default     = true

  validation {
    condition     = var.enable_nat_gateway || var.enable_ssm_endpoints
    error_message = "Redis needs a path to SSM: set enable_nat_gateway = true or enable_ssm_endpoints = true."
  }
}

# ---------------- Security groups ----------------
variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to SSH into the web instance. Must include the IP you run terraform from (the provisioners SSH in)."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.allowed_ssh_cidrs) > 0 && alltrue([for c in var.allowed_ssh_cidrs : can(cidrhost(c, 0))])
    error_message = "allowed_ssh_cidrs must be a non-empty list of valid CIDRs, e.g. [\"198.51.100.7/32\"]."
  }
}

variable "app_port" {
  description = "Port the Python redis-check app listens on"
  type        = number
  default     = 8000
}

# ---------------- Compute ----------------
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_index" {
  description = "AZ index to launch into: web uses that public subnet, redis that private subnet"
  type        = number
  default     = 0

  validation {
    condition     = var.subnet_index >= 0 && var.subnet_index < min(length(var.public_subnet_cidrs), length(var.private_subnet_cidrs))
    error_message = "subnet_index must point at an existing public and private subnet."
  }
}

# ---------------- Key pair ----------------
variable "create_key_pair" {
  description = "true: generate a new key pair (private key written to ./<project>-key.pem). false: use an existing EC2 key pair."
  type        = bool
  default     = true
}

variable "existing_key_name" {
  description = "Existing EC2 key pair name (only when create_key_pair = false)"
  type        = string
  default     = null

  validation {
    condition     = var.create_key_pair || var.existing_key_name != null
    error_message = "Set existing_key_name when create_key_pair = false."
  }
}

variable "existing_private_key_path" {
  description = "Path to the existing key pair's private key; the provisioners SSH in with it (only when create_key_pair = false)"
  type        = string
  default     = null

  validation {
    condition     = var.create_key_pair || var.existing_private_key_path != null
    error_message = "Set existing_private_key_path when create_key_pair = false."
  }
}
