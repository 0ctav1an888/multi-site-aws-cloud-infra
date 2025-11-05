terraform {
  required_version = ">=1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Llanelli VPC Module

module "llanelli" {
  source            = "../../modules/vpc"
  name              = "llanelli"
  cidr              = var.llanelli_vpc_cidr
  public_subnets    = var.llanelli_public_subnets
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

# Add routes to all private route tables (one per AZ)
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

# Add routes to all private route tables (one per AZ)
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
      cidr_blocks = ["10.10.0.0/16", "10.20.0.0/16"]
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
  monitoring         = true # Enable detailed monitoring
  enable_backup      = true # Enable automated backups
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
  monitoring         = true  # Enable detailed monitoring
  enable_backup      = false # Not critical for backups
  tags               = { Site = "llanelli", Role = "developer-server", Environment = "sandbox" }
}

module "llanelli_web_server" {
  source              = "../../modules/compute"
  name                = "llanelli-web-server"
  ami                 = var.ami_id
  instance_type       = "t3.micro"
  subnet_id           = module.llanelli.public_subnet_ids[0]
  private_ip          = "10.10.20.10"
  associate_public_ip = true
  key_name            = var.key_name
  security_group_ids  = [module.sg_llanelli_web_server.security_group_id]
  monitoring          = true  # Enable detailed monitoring
  enable_backup       = false # Stateless web server
  tags                = { Site = "llanelli", Role = "web-server", Environment = "sandbox" }
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
  monitoring         = false # Less critical
  enable_backup      = false # Less critical
  tags               = { Site = "llanelli", Role = "dhcp-server", Environment = "sandbox" }
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
  monitoring         = true # Enable detailed monitoring
  enable_backup      = true # Critical backup server needs backups
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
  monitoring         = true # Enable detailed monitoring
  enable_backup      = true # Email data is critical
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
  monitoring         = true # Enable detailed monitoring
  enable_backup      = true # Security server is critical
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
  monitoring         = false # Less critical
  enable_backup      = false # Less critical
  tags               = { Site = "cardiff", Role = "dhcp-server", Environment = "sandbox" }
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

# Application Load Balancer

module "llanelli_alb" {
  source          = "../../modules/alb"
  name            = "llanelli-alb"
  vpc_id          = module.llanelli.vpc_id
  subnets         = module.llanelli.public_subnet_ids
  security_groups = [module.sg_llanelli_alb.security_group_id]
  target_ids      = [module.llanelli_web_server.instance_id]
  target_port     = 80
  listener_port   = 80

  # Enable ALB Access Logging
  enable_access_logs         = true
  access_logs_bucket_name    = "llanelli-alb-logs-sandbox"
  access_logs_retention_days = 30

  tags = { Site = "llanelli", Role = "alb", Environment = "sandbox" }
}
# ===========================
# Backup Configuration
# ===========================

# Llanelli Backup Plan
module "llanelli_backup" {
  source = "../../modules/backup"

  vault_name = "llanelli-backup-vault"
  plan_name  = "llanelli-daily-backup"

  backup_schedule       = "cron(0 2 * * ? *)" # 2 AM UTC
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

  backup_schedule       = "cron(0 3 * * ? *)" # 3 AM UTC (staggered)
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

# ===========================
# CloudWatch Alarms & Monitoring
# ===========================

# Llanelli CloudWatch Alarms
module "llanelli_alarms" {
  source = "../../modules/cloudwatch_alarms"

  sns_topic_name = "llanelli-infrastructure-alarms"
  email_endpoints = [
    "ops-team@welshblanketfactory.com"
  ]

  # Map instance names to IDs
  instance_ids = {
    file-server      = module.llanelli_file_server.instance_id
    developer-server = module.llanelli_developer_server.instance_id
    web-server       = module.llanelli_web_server.instance_id
    dhcp-server      = module.llanelli_dhcp_server.instance_id
  }

  # ALB monitoring
  target_group_arns = {
    web-servers = module.llanelli_alb.target_group_arn
  }
  load_balancer_arn = module.llanelli_alb.alb_arn

  # Thresholds
  cpu_threshold           = 80
  response_time_threshold = 2.0
  error_5xx_threshold     = 10

  # Advanced monitoring (requires CloudWatch Agent installation)
  enable_disk_monitoring   = false # Enable after agent installed
  enable_memory_monitoring = false # Enable after agent installed

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
    "ops-team@welshblanketfactory.com"
  ]

  instance_ids = {
    backup-server   = module.cardiff_backup_server.instance_id
    email-server    = module.cardiff_email_server.instance_id
    security-server = module.cardiff_security_server.instance_id
    dhcp-server     = module.cardiff_dhcp_server.instance_id
  }

  cpu_threshold = 80

  # Cardiff doesn't have an ALB currently, so these are omitted
  # If/when Cardiff receives an ALB, add target_group_arns and load_balancer_arn here

  enable_disk_monitoring   = false
  enable_memory_monitoring = false

  tags = {
    Site        = "Cardiff"
    Environment = "sandbox"
  }
}
