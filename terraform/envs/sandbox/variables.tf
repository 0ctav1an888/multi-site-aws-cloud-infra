# Region Variable
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-2"
}

# Availability Zones
variable "azs" {
  type        = list(string)
  description = "Availability zones to distribute subnets across"
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

# Llanelli VPC CIDR and Subnets

variable "llanelli_vpc_cidr" {
  type        = string
  description = "CIDR for Llanelli VPC"
  default     = "10.10.0.0/16"
}

variable "llanelli_public_subnets" {
  type        = list(string)
  description = "List of CIDRs for public subnets for Llanelli"
  default     = ["10.10.40.0/24"]
}

variable "llanelli_dmz_subnets" {
  type        = list(string)
  description = "List of CIDRs for DMZ subnets for Llanelli"
  default     = [
    "10.10.20.0/25",
    "10.10.20.128/25"
  ]
}

variable "llanelli_private_subnets" {
  type        = list(string)
  description = "List of CIDRs for private/app subnets for Llanelli"
  default     = ["10.10.10.0/24"]
}

variable "llanelli_management_subnet" {
  type        = string
  description = "CIDR for management subnet in Llanelli"
  default     = "10.10.254.0/28"
}

variable "llanelli_guest_subnet" {
  type        = string
  description = "CIDR for guest Wi-Fi subnet in Llanelli"
  default     = "10.10.30.0/24"
}

variable "llanelli_client_vpn_cidr" {
  type        = string
  description = "Client VPN address pool for Llanelli"
  default     = "172.16.10.0/22"
}

# Cardiff VPC CIDR and Subnets

variable "cardiff_vpc_cidr" {
  type        = string
  description = "CIDR for Cardiff VPC"
  default     = "10.20.0.0/16"
}

variable "cardiff_public_subnets" {
  type        = list(string)
  description = "List of CIDRs for public subnets in Cardiff"
  default     = ["10.20.40.0/24"]
}

variable "cardiff_dmz_subnets" {
  type        = list(string)
  description = "List of CIDRs for DMZ subnets in Cardiff"
  default     = [
    "10.20.20.0/25",
    "10.20.20.128/25"
  ]
}

variable "cardiff_private_subnets" {
  type        = list(string)
  description = "List of CIDRs for private/app subnets in Cardiff"
  default     = ["10.20.10.0/24"]
}

variable "cardiff_management_subnet" {
  type        = string
  description = "CIDR for management subnet in Cardiff"
  default     = "10.20.254.0/28"
}

variable "cardiff_guest_subnet" {
  type        = string
  description = "CIDR for guest Wi-Fi subnet in Cardiff"
  default     = "10.20.30.0/24"
}

variable "cardiff_client_vpn_cidr" {
  type        = string
  description = "Client VPN address pool for Cardiff"
  default     = "172.16.20.0/22"
}

# Global Controls

variable "enable_nat" {
  type        = bool
  description = "Create a NAT Gateway for private subnets"
  default     = true
}

# Compute Resources

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instances"
  default     = "ami-0c1c30571d2dae5c9"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name for EC2 instances"
  default     = "welsh-blanket-factory"
}

variable "route53_domain_name" {
  type        = string
  description = "Public domain name for the web application"
  default     = "welshblanketfactory.com"
}

variable "route53_web_record_name" {
  type        = string
  description = "Web record name within the Route53 zone"
  default     = "www"
}
