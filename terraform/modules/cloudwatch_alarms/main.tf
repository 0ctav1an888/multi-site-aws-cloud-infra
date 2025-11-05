resource "aws_sns_topic" "alarms" {
  name = var.sns_topic_name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "alarms_email" {
  for_each = toset(var.email_endpoints)

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

locals {
  load_balancer_suffix = var.load_balancer_arn != "" ? element(split("loadbalancer/", var.load_balancer_arn), 1) : ""
  target_group_suffixes = {
    for name, arn in var.target_group_arns :
    name => element(split("targetgroup/", arn), 1)
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  for_each = var.instance_ids

  alarm_name          = "${each.key}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_period
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Triggers when CPU exceeds ${var.cpu_threshold}% for ${each.key}"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    InstanceId = each.value
  }

  tags = merge(var.tags, { Instance = each.key })
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  for_each = var.instance_ids

  alarm_name          = "${each.key}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Triggers when instance status check fails for ${each.key}"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    InstanceId = each.value
  }

  tags = merge(var.tags, { Instance = each.key })
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  for_each = var.enable_disk_monitoring ? var.instance_ids : {}

  alarm_name          = "${each.key}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = var.disk_threshold
  alarm_description   = "Triggers when disk usage exceeds ${var.disk_threshold}% for ${each.key}"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    InstanceId = each.value
    path       = "/"
    fstype     = "ext4"
  }

  tags = merge(var.tags, { Instance = each.key })
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  for_each = var.enable_memory_monitoring ? var.instance_ids : {}

  alarm_name          = "${each.key}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "Triggers when memory usage exceeds ${var.memory_threshold}% for ${each.key}"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    InstanceId = each.value
  }

  tags = merge(var.tags, { Instance = each.key })
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  for_each = var.target_group_arns

  alarm_name          = "${each.key}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Triggers when unhealthy targets detected in ${each.key}"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    TargetGroup  = local.target_group_suffixes[each.key]
    LoadBalancer = local.load_balancer_suffix
  }

  tags = merge(var.tags, { TargetGroup = each.key })
}

resource "aws_cloudwatch_metric_alarm" "response_time_high" {
  for_each = var.target_group_arns

  alarm_name          = "${each.key}-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = var.response_time_threshold
  alarm_description   = "Triggers when response time exceeds ${var.response_time_threshold}s for ${each.key}"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    TargetGroup  = local.target_group_suffixes[each.key]
    LoadBalancer = local.load_balancer_suffix
  }

  tags = merge(var.tags, { TargetGroup = each.key })
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  for_each = var.target_group_arns

  alarm_name          = "${each.key}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_5xx_threshold
  alarm_description   = "Triggers when 5XX errors exceed threshold for ${each.key}"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = local.target_group_suffixes[each.key]
    LoadBalancer = local.load_balancer_suffix
  }

  tags = merge(var.tags, { TargetGroup = each.key })
}
