resource "aws_vpn_gateway" "this" {
  count          = var.enable_site_to_site ? 1 : 0
  vpc_id         = var.vpc_id
  amazon_side_asn = var.vpn_gateway_asn

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_customer_gateway" "this" {
  count     = var.enable_site_to_site ? 1 : 0
  bgp_asn   = var.customer_gateway_bgp_asn
  ip_address = var.customer_gateway_ip
  type      = "ipsec.1"

  tags = merge(var.tags, { Name = "${var.name}-cgw" })
}

resource "aws_vpn_connection" "this" {
  count               = var.enable_site_to_site ? 1 : 0
  vpn_gateway_id      = aws_vpn_gateway.this[0].id
  customer_gateway_id = aws_customer_gateway.this[0].id
  type                = "ipsec.1"
  static_routes_only  = var.static_routes_only

  tags = merge(var.tags, { Name = "${var.name}-connection" })
}

resource "aws_vpn_connection_route" "this" {
  for_each          = var.enable_site_to_site ? toset(var.vpn_connection_static_routes) : []
  destination_cidr_block = each.value
  vpn_connection_id      = aws_vpn_connection.this[0].id
}

resource "aws_vpn_gateway_attachment" "this" {
  count         = var.enable_site_to_site ? 1 : 0
  vpc_id        = var.vpc_id
  vpn_gateway_id = aws_vpn_gateway.this[0].id
}

resource "aws_vpn_gateway_route_propagation" "this" {
  count          = var.enable_site_to_site ? length(var.route_table_ids) : 0
  vpn_gateway_id = aws_vpn_gateway.this[0].id
  route_table_id = var.route_table_ids[count.index]
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  count              = var.enable_client_vpn ? 1 : 0
  description        = "${var.name}-client-vpn"
  client_cidr_block  = var.client_vpn_cidr
  server_certificate_arn = var.client_vpn_server_certificate_arn
  split_tunnel       = var.client_vpn_split_tunnel
  transport_protocol = upper(var.client_vpn_transport_protocol)
  vpc_id             = var.vpc_id
  security_group_ids = var.client_vpn_security_group_ids
  dns_servers        = var.client_vpn_dns_servers

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_vpn_server_certificate_arn
  }

  connection_log_options {
    enabled               = var.client_vpn_connection_log_group_name != ""
    cloudwatch_log_group  = var.client_vpn_connection_log_group_name
    cloudwatch_log_stream = var.client_vpn_connection_log_stream
  }

  tags = merge(var.tags, { Name = "${var.name}-client-vpn" })
}

resource "aws_ec2_client_vpn_network_association" "this" {
  count                  = var.enable_client_vpn ? length(var.client_vpn_subnet_ids) : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  subnet_id              = var.client_vpn_subnet_ids[count.index]
}

resource "aws_ec2_client_vpn_authorization_rule" "this" {
  count                  = var.enable_client_vpn ? length(var.client_vpn_authorization_cidrs) : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  target_network_cidr    = var.client_vpn_authorization_cidrs[count.index]
  authorize_all_groups   = true
}

resource "aws_ec2_client_vpn_route" "this" {
  count                  = var.enable_client_vpn ? length(var.client_vpn_routes) : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  destination_cidr_block = var.client_vpn_routes[count.index]
  target_vpc_subnet_id   = var.client_vpn_subnet_ids[0]
}
