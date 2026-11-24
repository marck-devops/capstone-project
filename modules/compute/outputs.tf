output "web_instance_id" {
  value = aws_instance.web.id
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "web_public_dns" {
  value = aws_instance.web.public_dns
}

output "redis_instance_id" {
  value = aws_instance.redis.id
}

output "redis_private_ip" {
  value = aws_instance.redis.private_ip
}

output "key_name" {
  value = local.key_name
}

output "private_key_path" {
  description = "Local path of the private key used for SSH"
  value       = local.private_key_path
}
