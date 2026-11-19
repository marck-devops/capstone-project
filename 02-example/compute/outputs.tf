output "vpc_id" {
  description = "VPC found by tag lookup"
  value       = data.aws_vpc.main.id
}

output "subnet_id" {
  value = aws_instance.web.subnet_id
}

output "instance_id" {
  value = aws_instance.web.id
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "instance_public_dns" {
  value = aws_instance.web.public_dns
}

output "key_name" {
  value = aws_key_pair.web.key_name
}

output "ssh_command" {
  value = "ssh -i ${local_sensitive_file.private_key.filename} ec2-user@${aws_instance.web.public_ip}"
}
