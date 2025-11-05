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

variable "guest_subnet" {
  type        = string
  description = "CIDR for guest Wi-Fi subnet"
  default     = ""
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

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 7 # 7 days for cost optimization, increase for compliance needs
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to log (ALL, ACCEPT, REJECT)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_logs_traffic_type)
    error_message = "Traffic type must be ALL, ACCEPT, or REJECT."
  }
}

variable "flow_logs_max_aggregation_interval" {
  description = "Maximum interval for aggregating flow logs (60 or 600 seconds)"
  type        = number
  default     = 600 # 10 minutes for cost optimization

  validation {
    condition     = contains([60, 600], var.flow_logs_max_aggregation_interval)
    error_message = "Aggregation interval must be 60 or 600 seconds."
  }
}
