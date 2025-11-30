terraform {
  required_version = ">=1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Client VPN certificates

resource "tls_private_key" "client_vpn_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "client_vpn_ca" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.client_vpn_ca.private_key_pem

  subject {
    common_name  = "Welsh Blanket Factory VPN CA"
    organization = "Welsh Blanket Factory"
  }

  validity_period_hours = 87600
  is_ca_certificate     = true
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
}

resource "tls_private_key" "client_vpn_server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client_vpn_server" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.client_vpn_server.private_key_pem

  subject {
    common_name  = "vpn.${var.route53_domain_name}"
    organization = "Welsh Blanket Factory"
  }
}

resource "tls_locally_signed_cert" "client_vpn_server" {
  cert_request_pem   = tls_cert_request.client_vpn_server.cert_request_pem
  ca_private_key_pem = tls_private_key.client_vpn_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.client_vpn_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

resource "aws_acm_certificate" "client_vpn_server" {
  private_key       = tls_private_key.client_vpn_server.private_key_pem
  certificate_body  = tls_locally_signed_cert.client_vpn_server.cert_pem
  certificate_chain = tls_self_signed_cert.client_vpn_ca.cert_pem

  tags = {
    Name        = "vpn.${var.route53_domain_name}"
    Environment = "sandbox"
  }
}

resource "tls_private_key" "web_alb" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "web_alb" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.web_alb.private_key_pem

  subject {
    common_name  = "${var.route53_web_record_name}.${var.route53_domain_name}"
    organization = "Welsh Blanket Factory"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

resource "aws_acm_certificate" "web_alb" {
  private_key       = tls_private_key.web_alb.private_key_pem
  certificate_body  = tls_self_signed_cert.web_alb.cert_pem
  certificate_chain = tls_self_signed_cert.web_alb.cert_pem

  tags = {
    Name        = "${var.route53_web_record_name}.${var.route53_domain_name}"
    Environment = "sandbox"
  }
}

resource "aws_cloudwatch_log_group" "client_vpn" {
  name              = "/aws/vpn/client"
  retention_in_days = 14
  tags = {
    Application = "client-vpn"
    Environment = "sandbox"
  }
}

resource "aws_cloudwatch_log_stream" "client_vpn_llanelli" {
  name           = "llanelli"
  log_group_name = aws_cloudwatch_log_group.client_vpn.name
}

resource "aws_cloudwatch_log_stream" "client_vpn_cardiff" {
  name           = "cardiff"
  log_group_name = aws_cloudwatch_log_group.client_vpn.name
}

# Llanelli VPC Module

module "llanelli" {
  source            = "../../modules/vpc"
  name              = "llanelli"
  cidr              = var.llanelli_vpc_cidr
  public_subnets    = var.llanelli_public_subnets
  dmz_subnets       = var.llanelli_dmz_subnets
  private_subnets   = var.llanelli_private_subnets
  management_subnet = var.llanelli_management_subnet
  guest_subnet      = var.llanelli_guest_subnet
  azs               = var.azs
  enable_nat        = var.enable_nat

  # Enable VPC Flow Logs
  enable_flow_logs                   = true
  flow_logs_retention_days           = 7
  flow_logs_traffic_type             = "ALL"
  flow_logs_max_aggregation_interval = 600

  tags = {
    Site        = "Llanelli"
    Environment = "sandbox"
  }
}

module "cardiff" {
  source            = "../../modules/vpc"
  name              = "cardiff"
  cidr              = var.cardiff_vpc_cidr
  public_subnets    = var.cardiff_public_subnets
  dmz_subnets       = var.cardiff_dmz_subnets
  private_subnets   = var.cardiff_private_subnets
  management_subnet = var.cardiff_management_subnet
  guest_subnet      = var.cardiff_guest_subnet
  azs               = var.azs
  enable_nat        = var.enable_nat

  # Enable VPC Flow Logs
  enable_flow_logs                   = true
  flow_logs_retention_days           = 7
  flow_logs_traffic_type             = "ALL"
  flow_logs_max_aggregation_interval = 600

  tags = {
    Site        = "Cardiff"
    Environment = "sandbox"
  }
}

resource "aws_vpc_peering_connection" "llanelli_cardiff" {
  vpc_id      = module.llanelli.vpc_id
  peer_vpc_id = module.cardiff.vpc_id
  peer_region = var.aws_region
  auto_accept = true
}

# VPC Peering Routes - Llanelli to Cardiff

resource "aws_route" "llanelli_private_to_cardiff" {
  count                     = length(module.llanelli.private_route_table_ids)
  route_table_id            = module.llanelli.private_route_table_ids[count.index]
  destination_cidr_block    = var.cardiff_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.llanelli_cardiff.id
}

resource "aws_route" "llanelli_public_to_cardiff" {
  route_table_id            = module.llanelli.public_route_table_id
  destination_cidr_block    = var.cardiff_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.llanelli_cardiff.id
}

# VPC Peering Routes - Cardiff to Llanelli

resource "aws_route" "cardiff_private_to_llanelli" {
  count                     = length(module.cardiff.private_route_table_ids)
  route_table_id            = module.cardiff.private_route_table_ids[count.index]
  destination_cidr_block    = var.llanelli_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.llanelli_cardiff.id
}

resource "aws_route" "cardiff_public_to_llanelli" {
  route_table_id            = module.cardiff.public_route_table_id
  destination_cidr_block    = var.llanelli_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.llanelli_cardiff.id
}

# Llanelli Security Groups

module "sg_llanelli_file_server" {
  source      = "../../modules/security_group"
  name        = "llanelli-file-server-sg"
  description = "Security group for Llanelli file server"
  vpc_id      = module.llanelli.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.llanelli_management_subnet, var.cardiff_management_subnet]
      description = "SSH access"
    },
    {
      from_port   = 445
      to_port     = 445
      protocol    = "tcp"
      cidr_blocks = ["10.10.0.0/16", "10.20.0.0/16"]
      description = "SMB access"
    },
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = ["10.10.0.0/16", "10.20.0.0/16"]
      description = "NFS access"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "llanelli", Role = "file-server" }
}

module "sg_llanelli_developer_server" {
  source      = "../../modules/security_group"
  name        = "llanelli-developer-server-sg"
  description = "Security group for Llanelli developer server"
  vpc_id      = module.llanelli.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.10.0.0/16"]
      description = "SSH access"
    },
    {
      from_port   = 3000
      to_port     = 9000
      protocol    = "tcp"
      cidr_blocks = ["10.10.0.0/16"]
      description = "Development ports"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "llanelli", Role = "developer-server" }
}

module "sg_llanelli_web_server" {
  source      = "../../modules/security_group"
  name        = "llanelli-web-server-sg"
  description = "Security group for Llanelli web server"
  vpc_id      = module.llanelli.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.10.0.0/16", "10.20.0.0/16"]
      description = "SSH access"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "llanelli", Role = "web-server" }
}

module "sg_llanelli_dhcp_server" {
  source      = "../../modules/security_group"
  name        = "llanelli-dhcp-server-sg"
  description = "Security group for Llanelli DHCP server"
  vpc_id      = module.llanelli.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.10.0.0/16", "10.20.0.0/16"]
      description = "SSH access"
    },
    {
      from_port   = 67
      to_port     = 68
      protocol    = "udp"
      cidr_blocks = ["10.10.0.0/16"]
      description = "DHCP access"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "llanelli", Role = "dhcp-server" }
}

module "sg_llanelli_client_vpn" {
  source      = "../../modules/security_group"
  name        = "llanelli-client-vpn-sg"
  description = "Security group for Llanelli client VPN network interfaces"
  vpc_id      = module.llanelli.vpc_id
  ingress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [var.llanelli_client_vpn_cidr]
      description = "Allow client VPN traffic"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow outbound"
    }
  ]
  tags = { Site = "llanelli", Role = "client-vpn" }
}

module "sg_llanelli_security_server" {
  source      = "../../modules/security_group"
  name        = "llanelli-security-server-sg"
  description = "Security group for Llanelli security/RADIUS server"
  vpc_id      = module.llanelli.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.llanelli_management_subnet, var.cardiff_management_subnet]
      description = "SSH access"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.llanelli_management_subnet, var.cardiff_management_subnet]
      description = "HTTPS management"
    },
    {
      from_port   = 1812
      to_port     = 1813
      protocol    = "udp"
      cidr_blocks = ["10.10.0.0/16", "10.20.0.0/16"]
      description = "RADIUS authentication"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "llanelli", Role = "security-server" }
}

module "sg_llanelli_guest_wifi" {
  source      = "../../modules/security_group"
  name        = "llanelli-guest-wifi-sg"
  description = "Security group for Llanelli guest Wi-Fi gateway"
  vpc_id      = module.llanelli.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.llanelli_management_subnet]
      description = "SSH from management"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.llanelli_management_subnet]
      description = "HTTPS management"
    }
  ]
  egress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Guest web traffic"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Guest secure web traffic"
    }
  ]
  tags = { Site = "llanelli", Role = "guest-wifi" }
}

# Cardiff Security Groups

module "sg_cardiff_backup_server" {
  source      = "../../modules/security_group"
  name        = "cardiff-backup-server-sg"
  description = "Security group for Cardiff backup server"
  vpc_id      = module.cardiff.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16", "10.10.0.0/16"]
      description = "SSH access"
    },
    {
      from_port   = 9000
      to_port     = 9000
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16", "10.10.0.0/16"]
      description = "Backup service"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "cardiff", Role = "backup-server" }
}

module "sg_cardiff_email_server" {
  source      = "../../modules/security_group"
  name        = "cardiff-email-server-sg"
  description = "Security group for Cardiff email server"
  vpc_id      = module.cardiff.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16", "10.10.0.0/16"]
      description = "SSH access"
    },
    {
      from_port   = 25
      to_port     = 25
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16", "10.10.0.0/16"]
      description = "SMTP access"
    },
    {
      from_port   = 587
      to_port     = 587
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16", "10.10.0.0/16"]
      description = "SMTP submission"
    },
    {
      from_port   = 143
      to_port     = 143
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16", "10.10.0.0/16"]
      description = "IMAP access"
    },
    {
      from_port   = 993
      to_port     = 993
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16", "10.10.0.0/16"]
      description = "IMAP SSL"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "cardiff", Role = "email-server" }
}

module "sg_cardiff_web_server" {
  source      = "../../modules/security_group"
  name        = "cardiff-web-server-sg"
  description = "Security group for Cardiff web servers"
  vpc_id      = module.cardiff.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.cardiff_management_subnet, var.llanelli_management_subnet]
      description = "SSH access from management networks"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "cardiff", Role = "web-server" }
}

module "sg_cardiff_security_server" {
  source      = "../../modules/security_group"
  name        = "cardiff-security-server-sg"
  description = "Security group for Cardiff security server"
  vpc_id      = module.cardiff.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16"]
      description = "SSH access"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16", "10.10.0.0/16"]
      description = "HTTPS management"
    },
    {
      from_port   = 1812
      to_port     = 1813
      protocol    = "udp"
      cidr_blocks = ["10.10.0.0/16", "10.20.0.0/16"]
      description = "RADIUS authentication"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "cardiff", Role = "security-server" }
}

module "sg_cardiff_dhcp_server" {
  source      = "../../modules/security_group"
  name        = "cardiff-dhcp-server-sg"
  description = "Security group for Cardiff DHCP server"
  vpc_id      = module.cardiff.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.20.0.0/16", "10.10.0.0/16"]
      description = "SSH access"
    },
    {
      from_port   = 67
      to_port     = 68
      protocol    = "udp"
      cidr_blocks = ["10.20.0.0/16"]
      description = "DHCP access"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "cardiff", Role = "dhcp-server" }
}

module "sg_cardiff_client_vpn" {
  source      = "../../modules/security_group"
  name        = "cardiff-client-vpn-sg"
  description = "Security group for Cardiff client VPN network interfaces"
  vpc_id      = module.cardiff.vpc_id
  ingress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [var.cardiff_client_vpn_cidr]
      description = "Allow client VPN traffic"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow outbound"
    }
  ]
  tags = { Site = "cardiff", Role = "client-vpn" }
}

module "sg_cardiff_guest_wifi" {
  source      = "../../modules/security_group"
  name        = "cardiff-guest-wifi-sg"
  description = "Security group for Cardiff guest Wi-Fi gateway"
  vpc_id      = module.cardiff.vpc_id
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.cardiff_management_subnet]
      description = "SSH from management"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.cardiff_management_subnet]
      description = "HTTPS management"
    }
  ]
  egress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Guest web traffic"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Guest secure web traffic"
    }
  ]
  tags = { Site = "cardiff", Role = "guest-wifi" }
}

# Llanelli Compute Instances

module "llanelli_file_server" {
  source             = "../../modules/compute"
  name               = "llanelli-file-server"
  ami                = var.ami_id
  instance_type      = "t3.small"
  subnet_id          = module.llanelli.private_subnet_ids[0]
  private_ip         = "10.10.10.10"
  key_name           = var.key_name
  security_group_ids = [module.sg_llanelli_file_server.security_group_id]
  monitoring         = true 
  enable_backup      = true
  tags               = { Site = "llanelli", Role = "file-server", Environment = "sandbox" }
}

module "llanelli_developer_server" {
  source             = "../../modules/compute"
  name               = "llanelli-developer-server"
  ami                = var.ami_id
  instance_type      = "t3.small"
  subnet_id          = module.llanelli.private_subnet_ids[0]
  private_ip         = "10.10.10.11"
  key_name           = var.key_name
  security_group_ids = [module.sg_llanelli_developer_server.security_group_id]
  monitoring         = true 
  enable_backup      = true
  tags               = { Site = "llanelli", Role = "developer-server", Environment = "sandbox" }
}

module "llanelli_security_server" {
  source             = "../../modules/compute"
  name               = "llanelli-security-server"
  ami                = var.ami_id
  instance_type      = "t3.small"
  subnet_id          = module.llanelli.private_subnet_ids[0]
  private_ip         = "10.10.10.13"
  key_name           = var.key_name
  security_group_ids = [module.sg_llanelli_security_server.security_group_id]
  monitoring         = true 
  enable_backup      = true
  tags               = { Site = "llanelli", Role = "security-server", Environment = "sandbox" }
}

module "llanelli_dhcp_server" {
  source             = "../../modules/compute"
  name               = "llanelli-dhcp-server"
  ami                = var.ami_id
  instance_type      = "t3.micro"
  subnet_id          = module.llanelli.private_subnet_ids[0]
  private_ip         = "10.10.10.12"
  key_name           = var.key_name
  security_group_ids = [module.sg_llanelli_dhcp_server.security_group_id]
  monitoring         = true
  enable_backup      = true
  tags               = { Site = "llanelli", Role = "dhcp-server", Environment = "sandbox" }
}

module "llanelli_guest_wifi_gateway" {
  source              = "../../modules/compute"
  name                = "llanelli-guest-wifi-gateway"
  ami                 = var.ami_id
  instance_type       = "t3.micro"
  subnet_id           = module.llanelli.guest_subnet_id
  private_ip          = "10.10.30.10"
  associate_public_ip = true
  key_name            = var.key_name
  security_group_ids  = [module.sg_llanelli_guest_wifi.security_group_id]
  monitoring          = true
  enable_backup       = true
  tags                = { Site = "llanelli", Role = "guest-wifi", Environment = "sandbox" }
}

# Cardiff Compute Instances

module "cardiff_backup_server" {
  source             = "../../modules/compute"
  name               = "cardiff-backup-server"
  ami                = var.ami_id
  instance_type      = "t3.small"
  subnet_id          = module.cardiff.private_subnet_ids[0]
  private_ip         = "10.20.10.10"
  key_name           = var.key_name
  security_group_ids = [module.sg_cardiff_backup_server.security_group_id]
  monitoring         = true 
  enable_backup      = true
  tags               = { Site = "cardiff", Role = "backup-server", Environment = "sandbox" }
}

module "cardiff_email_server" {
  source             = "../../modules/compute"
  name               = "cardiff-email-server"
  ami                = var.ami_id
  instance_type      = "t3.small"
  subnet_id          = module.cardiff.private_subnet_ids[0]
  private_ip         = "10.20.10.11"
  key_name           = var.key_name
  security_group_ids = [module.sg_cardiff_email_server.security_group_id]
  monitoring         = true 
  enable_backup      = true
  tags               = { Site = "cardiff", Role = "email-server", Environment = "sandbox" }
}

module "cardiff_security_server" {
  source             = "../../modules/compute"
  name               = "cardiff-security-server"
  ami                = var.ami_id
  instance_type      = "t3.small"
  subnet_id          = module.cardiff.private_subnet_ids[0]
  private_ip         = "10.20.10.12"
  key_name           = var.key_name
  security_group_ids = [module.sg_cardiff_security_server.security_group_id]
  monitoring         = true 
  enable_backup      = true
  tags               = { Site = "cardiff", Role = "security-server", Environment = "sandbox" }
}

module "cardiff_dhcp_server" {
  source             = "../../modules/compute"
  name               = "cardiff-dhcp-server"
  ami                = var.ami_id
  instance_type      = "t3.micro"
  subnet_id          = module.cardiff.private_subnet_ids[0]
  private_ip         = "10.20.10.13"
  key_name           = var.key_name
  security_group_ids = [module.sg_cardiff_dhcp_server.security_group_id]
  monitoring         = true
  enable_backup      = true 
  tags               = { Site = "cardiff", Role = "dhcp-server", Environment = "sandbox" }
}

module "cardiff_guest_wifi_gateway" {
  source              = "../../modules/compute"
  name                = "cardiff-guest-wifi-gateway"
  ami                 = var.ami_id
  instance_type       = "t3.micro"
  subnet_id           = module.cardiff.guest_subnet_id
  private_ip          = "10.20.30.10"
  associate_public_ip = true
  key_name            = var.key_name
  security_group_ids  = [module.sg_cardiff_guest_wifi.security_group_id]
  monitoring          = true
  enable_backup       = true
  tags                = { Site = "cardiff", Role = "guest-wifi", Environment = "sandbox" }
}

# ALB Security Group

module "sg_llanelli_alb" {
  source      = "../../modules/security_group"
  name        = "llanelli-alb-sg"
  description = "Security group for Llanelli ALB"
  vpc_id      = module.llanelli.vpc_id
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from internet"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "llanelli", Role = "alb" }
}

module "sg_cardiff_alb" {
  source      = "../../modules/security_group"
  name        = "cardiff-alb-sg"
  description = "Security group for Cardiff ALB"
  vpc_id      = module.cardiff.vpc_id
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from internet"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
  tags = { Site = "cardiff", Role = "alb" }
}

# Application Load Balancer

module "llanelli_alb" {
  source          = "../../modules/alb"
  name            = "llanelli-alb"
  vpc_id          = module.llanelli.vpc_id
  subnets         = module.llanelli.dmz_subnet_ids
  security_groups = [module.sg_llanelli_alb.security_group_id]
  target_ids      = []
  target_port     = 80
  listener_port   = 443
  listener_protocol = "HTTPS"
  certificate_arn   = aws_acm_certificate.web_alb.arn
  enable_http_redirect = true
  enable_access_logs         = true
  access_logs_bucket_name    = "llanelli-alb-logs-sandbox" # S3 Bucket doesnt exist due to costs involved
  access_logs_retention_days = 30

  tags = { Site = "llanelli", Role = "alb", Environment = "sandbox" }
}

module "cardiff_alb" {
  source          = "../../modules/alb"
  name            = "cardiff-alb"
  vpc_id          = module.cardiff.vpc_id
  subnets         = module.cardiff.dmz_subnet_ids
  security_groups = [module.sg_cardiff_alb.security_group_id]
  target_ids      = []
  target_port     = 80
  listener_port   = 443
  listener_protocol = "HTTPS"
  certificate_arn   = aws_acm_certificate.web_alb.arn
  enable_http_redirect = true
  enable_access_logs         = true
  access_logs_bucket_name    = "cardiff-alb-logs-sandbox"
  access_logs_retention_days = 30

  tags = { Site = "cardiff", Role = "alb", Environment = "sandbox" }
}

# Web Auto Scaling Groups

module "llanelli_web_asg" {
  source                 = "../../modules/asg"
  name                   = "llanelli-web-asg"
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_ids             = module.llanelli.dmz_subnet_ids
  security_group_ids     = [module.sg_llanelli_web_server.security_group_id]
  key_name               = var.key_name
  desired_capacity       = 2
  min_size               = 2
  max_size               = 4
  target_group_arns      = [module.llanelli_alb.target_group_arn]
  cpu_target_value       = 45
  alb_target_requests    = 750
  alb_request_label      = "${module.llanelli_alb.alb_arn_suffix}/${module.llanelli_alb.target_group_arn_suffix}"
  health_check_grace_period = 180
  tags = {
    Site        = "llanelli"
    Role        = "web"
    Environment = "sandbox"
  }
}

module "cardiff_web_asg" {
  source                 = "../../modules/asg"
  name                   = "cardiff-web-asg"
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_ids             = module.cardiff.dmz_subnet_ids
  security_group_ids     = [module.sg_cardiff_web_server.security_group_id]
  key_name               = var.key_name
  desired_capacity       = 1
  min_size               = 1
  max_size               = 2
  target_group_arns      = [module.cardiff_alb.target_group_arn]
  cpu_target_value       = 50
  alb_target_requests    = 500
  alb_request_label      = "${module.cardiff_alb.alb_arn_suffix}/${module.cardiff_alb.target_group_arn_suffix}"
  health_check_grace_period = 180
  tags = {
    Site        = "cardiff"
    Role        = "web"
    Environment = "sandbox"
  }
}

# Client VPN Endpoints

module "llanelli_client_vpn" {
  source                     = "../../modules/vpn"
  name                       = "llanelli-client-vpn"
  vpc_id                     = module.llanelli.vpc_id
  customer_gateway_ip        = ""
  enable_site_to_site        = false
  enable_client_vpn          = true
  client_vpn_cidr            = var.llanelli_client_vpn_cidr
  client_vpn_security_group_ids = [module.sg_llanelli_client_vpn.security_group_id]
  client_vpn_subnet_ids      = [module.llanelli.management_subnet_id]
  client_vpn_routes          = [var.llanelli_vpc_cidr, var.cardiff_vpc_cidr]
  client_vpn_authorization_cidrs = [var.llanelli_vpc_cidr, var.cardiff_vpc_cidr]
  client_vpn_server_certificate_arn = aws_acm_certificate.client_vpn_server.arn
  client_vpn_connection_log_group_name = aws_cloudwatch_log_group.client_vpn.name
  client_vpn_connection_log_stream     = aws_cloudwatch_log_stream.client_vpn_llanelli.name
  client_vpn_dns_servers      = ["10.10.0.2"]
  tags = {
    Site        = "llanelli"
    Environment = "sandbox"
  }
}

module "cardiff_client_vpn" {
  source                     = "../../modules/vpn"
  name                       = "cardiff-client-vpn"
  vpc_id                     = module.cardiff.vpc_id
  customer_gateway_ip        = ""
  enable_site_to_site        = false
  enable_client_vpn          = true
  client_vpn_cidr            = var.cardiff_client_vpn_cidr
  client_vpn_security_group_ids = [module.sg_cardiff_client_vpn.security_group_id]
  client_vpn_subnet_ids      = [module.cardiff.management_subnet_id]
  client_vpn_routes          = [var.cardiff_vpc_cidr, var.llanelli_vpc_cidr]
  client_vpn_authorization_cidrs = [var.cardiff_vpc_cidr, var.llanelli_vpc_cidr]
  client_vpn_server_certificate_arn = aws_acm_certificate.client_vpn_server.arn
  client_vpn_connection_log_group_name = aws_cloudwatch_log_group.client_vpn.name
  client_vpn_connection_log_stream     = aws_cloudwatch_log_stream.client_vpn_cardiff.name
  client_vpn_dns_servers      = ["10.20.0.2"]
  tags = {
    Site        = "cardiff"
    Environment = "sandbox"
  }
}

# Route53 Failover

resource "aws_route53_zone" "wbf" {
  name = var.route53_domain_name
  tags = {
    Project     = "welsh-blanket-factory"
    Environment = "sandbox"
  }
}

resource "aws_route53_health_check" "llanelli_web" {
  fqdn              = module.llanelli_alb.alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3
  regions           = ["eu-west-1", "eu-west-2", "eu-west-3"]
}

resource "aws_route53_health_check" "cardiff_web" {
  fqdn              = module.cardiff_alb.alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3
  regions           = ["eu-west-1", "eu-west-2", "eu-west-3"]
}

resource "aws_route53_record" "web_primary" {
  zone_id = aws_route53_zone.wbf.zone_id
  name    = "${var.route53_web_record_name}.${var.route53_domain_name}"
  type    = "A"

  alias {
    name                   = module.llanelli_alb.alb_dns_name
    zone_id                = module.llanelli_alb.alb_zone_id
    evaluate_target_health = true
  }

  set_identifier = "llanelli-primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.llanelli_web.id
}

resource "aws_route53_record" "web_secondary" {
  zone_id = aws_route53_zone.wbf.zone_id
  name    = "${var.route53_web_record_name}.${var.route53_domain_name}"
  type    = "A"

  alias {
    name                   = module.cardiff_alb.alb_dns_name
    zone_id                = module.cardiff_alb.alb_zone_id
    evaluate_target_health = true
  }

  set_identifier = "cardiff-secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  health_check_id = aws_route53_health_check.cardiff_web.id
}

locals {
  client_vpn_profile_content = <<-EOT
client
dev tun
proto udp
remote ${aws_route53_record.web_primary.name} 443
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3
<ca>
${tls_self_signed_cert.client_vpn_ca.cert_pem}
</ca>
EOT
}

resource "local_file" "client_vpn_ca" {
  content  = tls_self_signed_cert.client_vpn_ca.cert_pem
  filename = "${path.root}/../../docs/vpn/client-vpn-ca.crt"
}

resource "local_file" "client_vpn_profile" {
  content  = local.client_vpn_profile_content
  filename = "${path.root}/../../docs/vpn/client-vpn-base.ovpn"
  depends_on = [aws_route53_record.web_primary]
}

# Llanelli Backup Plan
module "llanelli_backup" {
  source = "../../modules/backup"

  vault_name = "llanelli-backup-vault"
  plan_name  = "llanelli-daily-backup"

  backup_schedule       = "cron(0 2 * * ? *)"
  retention_days        = 30
  enable_weekly_backup  = true
  weekly_retention_days = 90

  backup_tag_key   = "Backup"
  backup_tag_value = "true"

  tags = {
    Site        = "Llanelli"
    Environment = "sandbox"
  }
}

# Cardiff Backup Plan
module "cardiff_backup" {
  source = "../../modules/backup"

  vault_name = "cardiff-backup-vault"
  plan_name  = "cardiff-daily-backup"

  backup_schedule       = "cron(0 3 * * ? *)" 
  retention_days        = 30
  enable_weekly_backup  = true
  weekly_retention_days = 90

  backup_tag_key   = "Backup"
  backup_tag_value = "true"

  tags = {
    Site        = "Cardiff"
    Environment = "sandbox"
  }
}

# Llanelli CloudWatch Alarms
module "llanelli_alarms" {
  source = "../../modules/cloudwatch_alarms"

  sns_topic_name = "llanelli-infrastructure-alarms"
  email_endpoints = [
    "ops-team@welshblanketfactory.com"
  ]

  instance_ids = {
    file-server      = module.llanelli_file_server.instance_id
    developer-server = module.llanelli_developer_server.instance_id
    security-server  = module.llanelli_security_server.instance_id
    dhcp-server      = module.llanelli_dhcp_server.instance_id
  }

  target_group_arns = {
    web-servers = module.llanelli_alb.target_group_arn
  }
  load_balancer_arn = module.llanelli_alb.alb_arn
  cpu_threshold           = 80
  response_time_threshold = 2.0
  error_5xx_threshold     = 10
  enable_disk_monitoring   = true 
  enable_memory_monitoring = true 

  tags = {
    Site        = "Llanelli"
    Environment = "sandbox"
  }
}

# Cardiff CloudWatch Alarms
module "cardiff_alarms" {
  source = "../../modules/cloudwatch_alarms"

  sns_topic_name = "cardiff-infrastructure-alarms"
  email_endpoints = [
    "work.lorenzofilippini@gmail.com"
    # WBF's emails here
  ]

  instance_ids = {
    backup-server   = module.cardiff_backup_server.instance_id
    email-server    = module.cardiff_email_server.instance_id
    security-server = module.cardiff_security_server.instance_id
    dhcp-server     = module.cardiff_dhcp_server.instance_id
  }

  target_group_arns = {
    web-servers = module.cardiff_alb.target_group_arn
  }
  load_balancer_arn = module.cardiff_alb.alb_arn

  cpu_threshold = 80

  enable_disk_monitoring   = true
  enable_memory_monitoring = true

  tags = {
    Site        = "Cardiff"
    Environment = "sandbox"
  }
}
