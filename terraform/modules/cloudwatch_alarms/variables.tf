variable "sns_topic_name" {
  description = "Name of SNS topic for alarm notifications"
  type        = string
}

variable "email_endpoints" {
  description = "List of email addresses to receive alarm notifications"
  type        = list(string)
}

variable "instance_ids" {
  description = "Map of instance names to instance IDs"
  type        = map(string)
  default     = {}
}

variable "target_group_arns" {
  description = "Map of target group names to full ARNs"
  type        = map(string)
  default     = {}
}

variable "load_balancer_arn" {
  description = "Load balancer ARN"
  type        = string
  default     = ""
}

# CPU Alarm Configuration
variable "cpu_threshold" {
  description = "CPU utilization threshold percentage"
  type        = number
  default     = 80
}

variable "cpu_period" {
  description = "Period in seconds for CPU alarm evaluation"
  type        = number
  default     = 300 # 5 minutes
}

variable "cpu_evaluation_periods" {
  description = "Number of periods to evaluate for CPU alarm"
  type        = number
  default     = 2
}

variable "enable_disk_monitoring" {
  description = "Enable disk space monitoring (requires CloudWatch Agent)"
  type        = bool
  default     = false 
}

variable "disk_threshold" {
  description = "Disk usage threshold percentage"
  type        = number
  default     = 85
}

variable "enable_memory_monitoring" {
  description = "Enable memory monitoring (requires CloudWatch Agent)"
  type        = bool
  default     = false #
}

variable "memory_threshold" {
  description = "Memory usage threshold percentage"
  type        = number
  default     = 85
}

variable "response_time_threshold" {
  description = "Target response time threshold in seconds"
  type        = number
  default     = 2.0
}

variable "error_5xx_threshold" {
  description = "Threshold for 5XX errors count"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to alarm resources"
  type        = map(string)
  default     = {}
}
