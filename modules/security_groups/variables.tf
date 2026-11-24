variable "name" {
  description = "Name prefix for every resource"
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the security groups in"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the web instance"
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
