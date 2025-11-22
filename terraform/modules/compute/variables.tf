variable "name" {
  type        = string
  description = "Name of the compute resource"
}

variable "ami" {
  type        = string
  description = "AMI ID for the compute resource"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
  default     = "t3.micro"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to place the instance in"
}

variable "private_ip" {
  type        = string
  description = "Private IP address to assign"
  default     = ""
}

variable "associate_public_ip" {
  type        = bool
  default     = false
  description = "Associate public IP address"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name"
  default     = ""
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "Security group IDs to attach"
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile name"
  default     = ""
}

variable "user_data" {
  type        = string
  description = "User data script content"
  default     = ""
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for context"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "root_volume_size" {
  type        = number
  description = "Root volume size in GB"
  default     = 20
}

variable "root_volume_type" {
  type        = string
  description = "Root volume type"
  default     = "gp3"
}

variable "monitoring" {
  type        = bool
  description = "Enable detailed monitoring"
  default     = false
}

variable "enable_backup" {
  description = "Enable automated backups for this instance"
  type        = bool
  default     = false
}
