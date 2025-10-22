variable "name" {
  type = string
  description = "Name of the compute resources"
}

variable "ami" {
  type = string
  description = "AMI type fo the compute resources"
}

variable "instance_type" {
  type = string
  description = "Type of AMI compute instance"
  default = "t3.micro"
}

variable "instance_count" {
  type = number
  description = "Amount of compute resources"
  default = 1
}

variable "subnet_id" {
  type = string
  description = "subnet id to place the instance in"
}

variable "associate_public_ip" {
  type = bool
  default = false
  description = "Whether instances should have public ip or not"
}

variable "key_name" {
  type = string
  description = "optional key pair for SSH access"
  default = ""
}

variable "security_group_ids" {
  type = list(string)
  default = []
  description = "Existing security groups to attach to instances"
}

variable "allow_ssh_cidr" {
  type = list(string)
  description = "list of CIDR allowed to SSH"
  default = []
}

variable "iam_instance_profile" {
  type = string
  description = "Optional IAM instance profile to attach"
}

variable "user_data" {
  type = string
  description = "Optional user_data script content"
  default = ""
}



