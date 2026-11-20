variable "aws_region" {
  description = "AWS region. Must match the network stack."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project tag of the network stack to look up. Must match the network stack."
  type        = string
  default     = "capstone-ex02"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_index" {
  description = "Which AZ index (subnets sorted by AZ) to launch into: the web instance uses that public subnet, redis that private subnet"
  type        = number
  default     = 0
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the web instance. Restrict this to your own IP (e.g. 1.2.3.4/32)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Port the Python redis-check app listens on (opened in the web security group)"
  type        = number
  default     = 8000
}
