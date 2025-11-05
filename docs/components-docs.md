# Modules Docs

## VPC Module
Creates a VPC with multiple subnet types

**Key Resources:**
- VPC with DNS support enabled
- Internet Gateway for internet access
- Public, Private, Management, and Guest subnets
- Route tables for each subnet
- Optional NAT Gateway for private subnet internet access

**Required Inputs:**
- name - VPC name prefix
- cidr - VPC CIDR block
- management_subnet - CIDR for management subnet
- azs - Availability zones list

**Optional Inputs:**
- public_subnets - List of public subnet CIDRs 
- private_subnets - List of private subnet CIDRs 
- guest_subnet - CIDR for guest Wi-Fi subnet 
- enable_nat - Create NAT gateway for private subnets

**Outputs:**
- vpc_id - VPC identifier
- public_subnet_ids / private_subnet_ids - Subnet identifiers
- management_subnet_id - Management subnet ID
- public_route_table_id / private_route_table_id - Route table IDs
- guest_subnet_id - Guest subnet ID


## Security Group Module
Creates AWS Security Groups with customizable inbound and outbound traffic rules

**Key Resources:**
- Security Group with dynamic ingress/egress rules

**Required Inputs:**
- name - Security group name
- description - Security group description
- vpc_id - VPC where the security group is created

**Optional Inputs:**
- ingress_rules - List of inbound rules
- egress_rules - List of outbound rules
- tags - Resource tags

**Outputs:**
- security_group_id - Security group identifier
- security_group_name - Security group name
- security_group_arn - Security group ARN

## Compute Module
Provisions EC2 instances with configurable specifications and security settings.

**Key Resources:**
- EC2 instance with encrypted root volume
- Configurable instance type, networking, and security

**Required Inputs:**
- name - Instance name
- ami - AMI ID to use for the instance
- subnet_id - Subnet where instance will be launched

**Optional Inputs:**
- instance_type - Instance size 
- private_ip - Fixed private IP address
- associate_public_ip - Assign public IP
- key_name - SSH key pair name 
- security_group_ids - List of security group IDs
- iam_instance_profile - IAM role for the instance
- user_data - Startup script
- root_volume_size - Root volume size in GB
- root_volume_type - Volume type 
- monitorin - Enable detailed monitoring

**Outputs:**
- instance_id - EC2 instance identifier
- private_ip / public_ip - IP addresses
- availability_zone - AZ where instance is running
- instance_state - Current instance state
- security_group_ids - Attached security groups

## ALB Module
Creates an Application Load Balancer to distribute traffic across multiple targets with health checking

**Key Resources:**
- Application Load Balancer
- Target Group with health checks
- HTTP/HTTPS Listener
- Target Group Attachments

**Required Inputs:**
- name - ALB name
- security_groups - List of security group IDs
- subnets - List of subnet IDs
- vpc_id - VPC identifier

**Optional Inputs:**
- internal - Internal ALB (
- enable_deletion_protection - Prevent accidental deletion
- target_port - Port on target instances 
- target_protocol - Protocol to target
- listener_port - Port the ALB listens on
- listener_protocol - Listener protocol
- target_ids - List of instance IDs to attach
- Health check settings

**Outputs:**
- alb_id / alb_arn - Load balancer identifiers
- alb_dns_name - DNS name to access the ALB
- target_group_arn - Target group ARN
- listener_arn - Listener ARN

## VPN Module
Establishes site-to-site VPN connectivity between AWS VPC and on premises networks

**Key Resources:**
- VPN Gateway
- Customer Gateway
- VPN Connection with IPsec tunnels
- Static routes and route propagation

**Required Inputs:**
- name - VPN connection name
- vpc_id - VPC identifier
- customer_gateway_ip - Public IP of on-premises VPN device

**Optional Inputs:**
- vpn_gateway_asn - AWS-side BGP ASN
- customer_gateway_bgp_asn - Customer-side BGP ASN
- static_routes_only - Use static routing instead of BGP
- vpn_connection_static_routes - List of static 
- route_table_ids - Route tables for route propagation

**Outputs:**
- vpn_gateway_id - VPN gateway identifier
- customer_gateway_id - Customer gateway identifier
- vpn_connection_id - VPN connection identifier
- vpn_connection_tunnel1_address / tunnel2_address - Tunnel endpoints
- vpn_connection_tunnel1_preshared_key / tunnel2_preshared_key - Tunnel PSKs
