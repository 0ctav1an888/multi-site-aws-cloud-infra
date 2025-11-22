variable "name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "ami" {
  description = "AMI ID used for the launch template"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the ASG"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets spanned by the ASG"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups applied to instances"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script"
  type        = string
  default     = ""
}

variable "desired_capacity" {
  description = "Desired capacity"
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "target_group_arns" {
  description = "Target groups the ASG should register with"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "Health check type"
  type        = string
  default     = "ELB"
}

variable "health_check_grace_period" {
  description = "Seconds before health checks start"
  type        = number
  default     = 120
}

variable "termination_policies" {
  description = "Termination policies"
  type        = list(string)
  default     = ["OldestLaunchConfiguration", "Default"]
}

variable "tags" {
  description = "Tags applied to ASG resources"
  type        = map(string)
  default     = {}
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring on instances"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Root EBS volume size"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "block_device_mappings" {
  description = "Optional block device mappings"
  type        = list(any)
  default     = []
}

variable "cpu_target_value" {
  description = "CPU utilization target for scaling"
  type        = number
  default     = 50
}

variable "alb_target_requests" {
  description = "ALB requests per target before scaling"
  type        = number
  default     = 1000
}

variable "alb_request_label" {
  description = "Resource label for ALBRequestCountPerTarget metric"
  type        = string
  default     = ""
}
