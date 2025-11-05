output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet ids"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of private subnet ids"
  value       = [for s in aws_subnet.private : s.id]
}

output "management_subnet_id" {
  description = "Management subnet id"
  value       = aws_subnet.management.id
}

output "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  value       = [for s in aws_subnet.public : s.cidr_block]
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  value       = [for s in aws_subnet.private : s.cidr_block]
}

output "private_route_table_id" {
  description = "Private route table id for the VPC (first one for backward compatibility)"
  value       = length(aws_route_table.private) > 0 ? aws_route_table.private[0].id : null
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = [for rt in aws_route_table.private : rt.id]
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "Public route table id for the VPC"
  value       = aws_route_table.public.id
}

output "guest_subnet_id" {
  description = "Guest Wi-Fi subnet ID"
  value       = length(aws_subnet.guest) > 0 ? aws_subnet.guest[0].id : null
}

output "guest_subnet_cidr" {
  description = "Guest Wi-Fi subnet CIDR"
  value       = length(aws_subnet.guest) > 0 ? aws_subnet.guest[0].cidr_block : null
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = var.enable_flow_logs ? aws_flow_log.main[0].id : null
}

output "flow_log_group_name" {
  description = "Name of the CloudWatch Log Group for flow logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
