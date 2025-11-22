output "vpn_gateway_id" {
  description = "VPN gateway ID"
  value       = var.enable_site_to_site ? aws_vpn_gateway.this[0].id : null
}

output "customer_gateway_id" {
  description = "Customer gateway ID"
  value       = var.enable_site_to_site ? aws_customer_gateway.this[0].id : null
}

output "vpn_connection_id" {
  description = "VPN connection ID"
  value       = var.enable_site_to_site ? aws_vpn_connection.this[0].id : null
}

output "vpn_connection_tunnel1_address" {
  description = "VPN connection tunnel 1 address"
  value       = var.enable_site_to_site ? aws_vpn_connection.this[0].tunnel1_address : null
}

output "vpn_connection_tunnel1_preshared_key" {
  description = "VPN connection tunnel 1 preshared key"
  value       = var.enable_site_to_site ? aws_vpn_connection.this[0].tunnel1_preshared_key : null
  sensitive   = true
}

output "vpn_connection_tunnel2_address" {
  description = "VPN connection tunnel 2 address"
  value       = var.enable_site_to_site ? aws_vpn_connection.this[0].tunnel2_address : null
}

output "vpn_connection_tunnel2_preshared_key" {
  description = "VPN connection tunnel 2 preshared key"
  value       = var.enable_site_to_site ? aws_vpn_connection.this[0].tunnel2_preshared_key : null
  sensitive   = true
}

output "client_vpn_endpoint_id" {
  description = "Client VPN endpoint ID"
  value       = var.enable_client_vpn ? aws_ec2_client_vpn_endpoint.this[0].id : null
}

output "client_vpn_association_ids" {
  description = "Client VPN association IDs"
  value       = var.enable_client_vpn ? [for assoc in aws_ec2_client_vpn_network_association.this : assoc.id] : []
}
