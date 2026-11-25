variable "name" {
  description = "Name prefix for every resource"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per AZ (in AZ order)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets, one per AZ (in AZ order)"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway (and its EIP) so the private subnets have outbound internet access"
  type        = bool
  default     = true
}

variable "enable_s3_gateway_endpoint" {
  description = "Create a free S3 gateway endpoint on the private route table. Amazon Linux 2023 package repos are served from S3, so this lets private instances run dnf without a NAT gateway."
  type        = bool
  default     = true
}

variable "enable_ssm_endpoints" {
  description = "Create interface endpoints (ssm, ssmmessages, ec2messages) in the private subnets so private instances can use Session Manager without a NAT gateway. Each endpoint is billed hourly per AZ."
  type        = bool
  default     = false
}
