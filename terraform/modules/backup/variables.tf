variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
}

variable "plan_name" {
  description = "Name of the backup plan"
  type        = string
}

variable "backup_schedule" {
  description = "Cron expression for backup schedule"
  type        = string
  default     = "cron(0 2 * * ? *)" # 2AM daily
}

variable "retention_days" {
  description = "Number of days to retain daily backups"
  type        = number
  default     = 30
}

variable "enable_weekly_backup" {
  description = "Enable weekly backups with extended retention"
  type        = bool
  default     = true
}

variable "weekly_retention_days" {
  description = "Number of days to retain weekly backups"
  type        = number
  default     = 90
}

variable "backup_tag_key" {
  description = "Tag key to identify resources for backup"
  type        = string
  default     = "Backup"
}

variable "backup_tag_value" {
  description = "Tag value to identify resources for backup"
  type        = string
  default     = "true"
}

variable "resource_arns" {
  description = "List of specific resource ARNs to backup"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to backup resources"
  type        = map(string)
  default     = {}
}
