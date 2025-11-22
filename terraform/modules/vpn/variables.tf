variable "name" {
  type        = string
  description = "VPN name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpn_gateway_asn" {
  type        = number
  description = "VPN gateway ASN"
  default     = 64512
}

variable "customer_gateway_ip" {
  type        = string
  description = "Customer gateway public IP"
  default     = ""
}

variable "enable_site_to_site" {
  type        = bool
  description = "Enable site-to-site VPN resources"
  default     = true
}

variable "enable_client_vpn" {
  type        = bool
  description = "Enable AWS Client VPN endpoint"
  default     = false
}

variable "customer_gateway_bgp_asn" {
  type        = number
  description = "Customer gateway BGP ASN"
  default     = 65000
}

variable "static_routes_only" {
  type        = bool
  description = "Use static routes only"
  default     = true
}

variable "vpn_connection_static_routes" {
  type        = list(string)
  description = "VPN connection static routes"
  default     = []
}

variable "route_table_ids" {
  type        = list(string)
  description = "Route table IDs for route propagation"
  default     = []
}

variable "client_vpn_cidr" {
  type        = string
  description = "Client VPN address pool"
  default     = ""
}

variable "client_vpn_security_group_ids" {
  type        = list(string)
  description = "Security groups applied to Client VPN"
  default     = []
}

variable "client_vpn_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs to associate the Client VPN endpoint to"
  default     = []
}

variable "client_vpn_routes" {
  type        = list(string)
  description = "CIDR routes propagated to VPN clients"
  default     = []
}

variable "client_vpn_authorization_cidrs" {
  type        = list(string)
  description = "Network CIDRs clients are authorized to access"
  default     = []
}

variable "client_vpn_server_certificate_arn" {
  type        = string
  description = "ACM certificate ARN used by the Client VPN endpoint"
  default     = ""
}

variable "client_vpn_split_tunnel" {
  type        = bool
  description = "Enable split tunnel for Client VPN"
  default     = true
}

variable "client_vpn_connection_log_group_name" {
  type        = string
  description = "CloudWatch log group name for connection logging"
  default     = ""
}

variable "client_vpn_connection_log_stream" {
  type        = string
  description = "CloudWatch log stream name"
  default     = ""
}

variable "client_vpn_transport_protocol" {
  type        = string
  description = "Transport protocol for Client VPN"
  default     = "udp"
}

variable "client_vpn_dns_servers" {
  type        = list(string)
  description = "Optional DNS servers push to VPN clients"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
