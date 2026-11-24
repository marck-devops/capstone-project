output "vpc_id" {
  value = module.network.vpc_id
}

output "nat_gateway_public_ip" {
  description = "null when enable_nat_gateway = false"
  value       = module.network.nat_gateway_public_ip
}

output "web_instance_id" {
  value = module.compute.web_instance_id
}

output "web_public_ip" {
  value = module.compute.web_public_ip
}

output "redis_private_ip" {
  value = module.compute.redis_private_ip
}

output "key_name" {
  value = module.compute.key_name
}

output "ssh_command" {
  value = "ssh -i ${module.compute.private_key_path} ec2-user@${module.compute.web_public_ip}"
}

output "redis_ssh_command" {
  description = "SSH to redis through the web instance"
  value       = "ssh -i ${module.compute.private_key_path} -J ec2-user@${module.compute.web_public_ip} ec2-user@${module.compute.redis_private_ip}"
}

output "app_url" {
  value = "http://${module.compute.web_public_ip}"
}

output "redis_instance_id" {
  value = module.compute.redis_instance_id
}

output "redis_iam_role_name" {
  value = module.redis_iam.role_name
}

output "redis_ssm_command" {
  description = "Open a shell on redis via Session Manager (needs the session-manager-plugin locally)"
  value       = "aws ssm start-session --target ${module.compute.redis_instance_id} --region ${var.aws_region} --profile ${var.aws_profile}"
}
