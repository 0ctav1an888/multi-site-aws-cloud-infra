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
  description = "Private route table id for the VPC"
  value       = aws_route_table.private.id
}

output "public_route_table_id" {
  description = "Public route table id for the VPC"
  value       = aws_route_table.public.id
}
