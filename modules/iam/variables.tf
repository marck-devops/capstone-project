variable "name" {
  description = "Name prefix for every resource"
  type        = string
}

variable "role_suffix" {
  description = "Suffix for the role and instance profile names: <name>-<role_suffix>-role / -profile"
  type        = string
  default     = "ssm"
}

variable "extra_policy_arns" {
  description = "Additional managed policy ARNs to attach to the role (AmazonSSMManagedInstanceCore is always attached)"
  type        = list(string)
  default     = []
}
