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
  description = "Which public subnet (sorted by AZ) to launch the instance into"
  type        = number
  default     = 0
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}