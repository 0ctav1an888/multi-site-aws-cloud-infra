output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "cpu_alarm_arns" {
  description = "ARNs of CPU utilization alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.cpu_high : k => v.arn }
}

output "status_check_alarm_arns" {
  description = "ARNs of status check alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.status_check_failed : k => v.arn }
}
