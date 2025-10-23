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
  description = "List of CIDRs for public/DMZ subnets for Llanelli"
  default     = ["10.10.20.0/24"]
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

# Cardiff VPC CIDR and Subnets

variable "cardiff_vpc_cidr" {
  type        = string
  description = "CIDR for Cardiff VPC"
  default     = "10.20.0.0/16"
}

variable "cardiff_public_subnets" {
  type        = list(string)
  description = "List of CIDRs for public/DMZ subnets in Cardiff"
  default     = ["10.20.20.0/24"]
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
