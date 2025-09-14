variable "name" {
  type        = string
  description = "Name prefix for the VPC"
}

variable "cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of CIDRs for public subnets"
  default     = []
}

variable "private_subnets" {
  type        = list(string)
  description = "List of CIDRs for private subnets"
  default     = []
}

variable "management_subnet" {
  type        = string
  description = "CIDR for management subnet"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to place subnets into"
  default     = []
}

variable "enable_nat" {
  type        = bool
  description = "Whether to create a NAT gateway for private subnets"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to add to resources"
  default     = {}
}
