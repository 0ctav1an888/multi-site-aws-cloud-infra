output "vault_id" {
  description = "ID of the backup vault"
  value       = aws_backup_vault.main.id
}

output "vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.main.arn
}

output "plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.main.id
}

output "plan_arn" {
  description = "ARN of the backup plan"
  value       = aws_backup_plan.main.arn
}
