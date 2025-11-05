resource "aws_backup_vault" "main" {
  name = var.vault_name
  tags = var.tags
}

resource "aws_backup_plan" "main" {
  name = var.plan_name
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = var.backup_schedule

    lifecycle {
      delete_after = var.retention_days 
    }

    recovery_point_tags = merge(var.tags, {
      BackupType = "Automated"
    })
  }

  dynamic "rule" {
    for_each = var.enable_weekly_backup ? [1] : []

    content {
      rule_name         = "weekly_backup"
      target_vault_name = aws_backup_vault.main.name
      schedule          = "cron(0 3 ? * SUN *)"

      lifecycle {
        delete_after = var.weekly_retention_days
      }

      recovery_point_tags = merge(var.tags, {
        BackupType = "Weekly"
      })
    }
  }

  tags = var.tags
}

resource "aws_iam_role" "backup" {
  name               = "${var.plan_name}-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_selection" "main" {
  name         = "${var.plan_name}-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_tag_key
    value = var.backup_tag_value 
  }
}
