output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs, in AZ order"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs, in AZ order"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_public_ip" {
  description = "NAT gateway public IP, or null when the NAT gateway is disabled"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

output "private_egress_ids" {
  description = "IDs of the private subnets' outbound paths (NAT route, S3 endpoint). Lets callers wait for them."
  value       = compact([one(aws_route.private_nat[*].id), one(aws_vpc_endpoint.s3[*].id)])
}

output "ssm_endpoint_ids" {
  description = "IDs of the SSM interface endpoints (empty when enable_ssm_endpoints = false)"
  value       = [for e in aws_vpc_endpoint.ssm : e.id]
}
