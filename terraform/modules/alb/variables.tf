variable "name" {
  type        = string
  description = "ALB name"
}

variable "internal" {
  type        = bool
  description = "Internal ALB"
  default     = false
}

variable "security_groups" {
  type        = list(string)
  description = "Security group IDs"
}

variable "subnets" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection"
  default     = false
}

variable "target_port" {
  type        = number
  description = "Target port"
  default     = 80
}

variable "target_protocol" {
  type        = string
  description = "Target protocol"
  default     = "HTTP"
}

variable "listener_port" {
  type        = number
  description = "Listener port"
  default     = 80
}

variable "listener_protocol" {
  type        = string
  description = "Listener protocol"
  default     = "HTTP"
}

variable "target_ids" {
  type        = list(string)
  description = "Target instance IDs"
  default     = []
}

variable "health_check_enabled" {
  type        = bool
  description = "Enable health checks"
  default     = true
}

variable "health_check_interval" {
  type        = number
  description = "Health check interval in seconds"
  default     = 30
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = "/"
}

variable "health_check_port" {
  type        = string
  description = "Health check port"
  default     = "traffic-port"
}

variable "health_check_protocol" {
  type        = string
  description = "Health check protocol"
  default     = "HTTP"
}

variable "health_check_timeout" {
  type        = number
  description = "Health check timeout in seconds"
  default     = 5
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "Healthy threshold"
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "Unhealthy threshold"
  default     = 2
}

variable "health_check_matcher" {
  type        = string
  description = "Health check matcher"
  default     = "200"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "enable_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
}

variable "access_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs"
  type        = string
  default     = ""
}

variable "access_logs_retention_days" {
  description = "Number of days to retain ALB access logs"
  type        = number
  default     = 30
}
