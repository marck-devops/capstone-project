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
  default     = "capstone-ex03"
}

# ---------------- Network ----------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.20.0/24"]
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

# ---------------- Security groups ----------------
variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the web instance. Must include the IP you run terraform from (the provisioners SSH in)."
  type        = string
  default     = "0.0.0.0/0"
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
