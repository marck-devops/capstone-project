variable "name" {
  description = "Name prefix for every resource"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for both instances"
  type        = string
  default     = "t3.micro"
}

variable "web_subnet_id" {
  description = "Public subnet for the web instance"
  type        = string
}

variable "redis_subnet_id" {
  description = "Private subnet for the redis instance"
  type        = string
}

variable "web_sg_id" {
  description = "Security group for the web instance"
  type        = string
}

variable "redis_sg_id" {
  description = "Security group for the redis instance"
  type        = string
}

variable "app_port" {
  description = "Port the Python redis-check app listens on"
  type        = number
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

# ---------------- Key pair ----------------
variable "create_key_pair" {
  description = "true: generate a new key pair. false: use existing_key_name / existing_private_key_path."
  type        = bool
  default     = true
}

variable "private_key_output_dir" {
  description = "Directory the generated private key is written to (create_key_pair = true only)"
  type        = string
  default     = "."
}

variable "existing_key_name" {
  description = "Name of a key pair that already exists in EC2 (create_key_pair = false only)"
  type        = string
  default     = null

  validation {
    condition     = var.create_key_pair || var.existing_key_name != null
    error_message = "existing_key_name is required when create_key_pair = false."
  }
}

variable "existing_private_key_path" {
  description = "Local path to the private key of existing_key_name. Terraform's provisioners SSH in with it (create_key_pair = false only)."
  type        = string
  default     = null

  validation {
    condition     = var.create_key_pair || var.existing_private_key_path != null
    error_message = "existing_private_key_path is required when create_key_pair = false (the provisioners need it to SSH in)."
  }
}

variable "private_egress_ids" {
  description = "IDs from the network module that the redis setup waits for (it installs packages)"
  type        = list(string)
  default     = []
}

# ---------------- IAM ----------------
variable "web_iam_instance_profile" {
  description = "IAM instance profile name for the web instance (null = none)"
  type        = string
  default     = null
}

variable "redis_iam_instance_profile" {
  description = "IAM instance profile name for the redis instance, e.g. one with AmazonSSMManagedInstanceCore for Session Manager (null = none)"
  type        = string
  default     = null
}
