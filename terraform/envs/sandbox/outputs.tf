# Llanelli Outputs
output "llanelli_vpc_id" {
  description = "Llanelli VPC ID"
  value       = try(module.llanelli.vpc_id, null)
}

output "llanelli_public_subnets_ids" {
  description = "List of Llanelli Public Subnet IDs"
  value       = try(module.llanelli.public_subnet_ids, [])
}

output "llanelli_dmz_subnet_ids" {
  description = "List of Llanelli DMZ Subnet IDs"
  value       = try(module.llanelli.dmz_subnet_ids, [])
}

output "llanelli_private_subnet_ids" {
  description = "List of Llanelli Private Subnet IDS"
  value       = try(module.llanelli.private_subnet_ids, [])
}

output "llanelli_management_subnet_ids" {
  description = "Llanelli Management Subnet ID"
  value       = try(module.llanelli.management_subnet_id, null)
}

# Cardiff Outputs

output "cardiff_vpc_id" {
  description = "cardiff VPC ID"
  value       = try(module.cardiff.vpc_id, null)
}

output "cardiff_public_subnets_ids" {
  description = "List of cardiff Public Subnet IDs"
  value       = try(module.cardiff.public_subnet_ids, [])
}

output "cardiff_dmz_subnet_ids" {
  description = "List of cardiff DMZ Subnet IDs"
  value       = try(module.cardiff.dmz_subnet_ids, [])
}

output "cardiff_private_subnet_ids" {
  description = "List of cardiff Private Subnet IDS"
  value       = try(module.cardiff.private_subnet_ids, [])
}

output "cardiff_management_subnet_ids" {
  description = "cardiff Management Subnet ID"
  value       = try(module.cardiff.management_subnet_id, null)
}

# Llanelli Compute Outputs

output "llanelli_file_server_id" {
  description = "Llanelli file server instance ID"
  value       = module.llanelli_file_server.instance_id
}

output "llanelli_file_server_private_ip" {
  description = "Llanelli file server private IP"
  value       = module.llanelli_file_server.private_ip
}

output "llanelli_developer_server_id" {
  description = "Llanelli developer server instance ID"
  value       = module.llanelli_developer_server.instance_id
}

output "llanelli_developer_server_private_ip" {
  description = "Llanelli developer server private IP"
  value       = module.llanelli_developer_server.private_ip
}

output "llanelli_security_server_id" {
  description = "Llanelli security server instance ID"
  value       = module.llanelli_security_server.instance_id
}

output "llanelli_security_server_private_ip" {
  description = "Llanelli security server private IP"
  value       = module.llanelli_security_server.private_ip
}

output "llanelli_dhcp_server_id" {
  description = "Llanelli DHCP server instance ID"
  value       = module.llanelli_dhcp_server.instance_id
}

output "llanelli_dhcp_server_private_ip" {
  description = "Llanelli DHCP server private IP"
  value       = module.llanelli_dhcp_server.private_ip
}

output "llanelli_web_asg_name" {
  description = "Name of the Llanelli web Auto Scaling Group"
  value       = module.llanelli_web_asg.asg_name
}

output "llanelli_guest_wifi_gateway_ip" {
  description = "Llanelli guest Wi-Fi gateway private IP"
  value       = module.llanelli_guest_wifi_gateway.private_ip
}

# Cardiff Compute Outputs

output "cardiff_backup_server_id" {
  description = "Cardiff backup server instance ID"
  value       = module.cardiff_backup_server.instance_id
}

output "cardiff_backup_server_private_ip" {
  description = "Cardiff backup server private IP"
  value       = module.cardiff_backup_server.private_ip
}

output "cardiff_email_server_id" {
  description = "Cardiff email server instance ID"
  value       = module.cardiff_email_server.instance_id
}

output "cardiff_email_server_private_ip" {
  description = "Cardiff email server private IP"
  value       = module.cardiff_email_server.private_ip
}

output "cardiff_security_server_id" {
  description = "Cardiff security server instance ID"
  value       = module.cardiff_security_server.instance_id
}

output "cardiff_security_server_private_ip" {
  description = "Cardiff security server private IP"
  value       = module.cardiff_security_server.private_ip
}

output "cardiff_dhcp_server_id" {
  description = "Cardiff DHCP server instance ID"
  value       = module.cardiff_dhcp_server.instance_id
}

output "cardiff_dhcp_server_private_ip" {
  description = "Cardiff DHCP server private IP"
  value       = module.cardiff_dhcp_server.private_ip
}

output "cardiff_web_asg_name" {
  description = "Name of the Cardiff web Auto Scaling Group"
  value       = module.cardiff_web_asg.asg_name
}

output "cardiff_guest_wifi_gateway_ip" {
  description = "Cardiff guest Wi-Fi gateway private IP"
  value       = module.cardiff_guest_wifi_gateway.private_ip
}

output "llanelli_client_vpn_endpoint_id" {
  description = "Client VPN endpoint for Llanelli"
  value       = module.llanelli_client_vpn.client_vpn_endpoint_id
}

output "cardiff_client_vpn_endpoint_id" {
  description = "Client VPN endpoint for Cardiff"
  value       = module.cardiff_client_vpn.client_vpn_endpoint_id
}

# ALB Outputs

output "llanelli_alb_dns_name" {
  description = "Llanelli ALB DNS name"
  value       = module.llanelli_alb.alb_dns_name
}

output "llanelli_alb_arn" {
  description = "Llanelli ALB ARN"
  value       = module.llanelli_alb.alb_arn
}

output "llanelli_alb_target_group_arn" {
  description = "Llanelli ALB target group ARN"
  value       = module.llanelli_alb.target_group_arn
}

output "cardiff_alb_dns_name" {
  description = "Cardiff ALB DNS name"
  value       = module.cardiff_alb.alb_dns_name
}

output "cardiff_alb_arn" {
  description = "Cardiff ALB ARN"
  value       = module.cardiff_alb.alb_arn
}

output "cardiff_alb_target_group_arn" {
  description = "Cardiff ALB target group ARN"
  value       = module.cardiff_alb.target_group_arn
}
