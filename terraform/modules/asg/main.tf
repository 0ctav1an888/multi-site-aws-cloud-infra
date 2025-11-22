resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  network_interfaces {
    security_groups = var.security_group_ids
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != "" ? [var.iam_instance_profile] : []

    content {
      name = iam_instance_profile.value
    }
  }

  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = var.name })
  }

  dynamic "block_device_mappings" {
    for_each = length(var.block_device_mappings) > 0 ? var.block_device_mappings : []

    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        delete_on_termination = lookup(block_device_mappings.value, "delete_on_termination", true)
        encrypted             = lookup(block_device_mappings.value, "encrypted", true)
        iops                  = lookup(block_device_mappings.value, "iops", null)
        throughput            = lookup(block_device_mappings.value, "throughput", null)
        volume_size           = lookup(block_device_mappings.value, "volume_size", var.root_volume_size)
        volume_type           = lookup(block_device_mappings.value, "volume_type", var.root_volume_type)
      }
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = var.name
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  termination_policies      = var.termination_policies
  metrics_granularity       = "1Minute"

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTotalInstances"
  ]

  dynamic "tag" {
    for_each = merge(var.tags, { Name = var.name })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_policy" "cpu_tracking" {
  name                   = "${var.name}-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_value
  }
}

resource "aws_autoscaling_policy" "alb_requests" {
  count                  = var.alb_request_label != "" ? 1 : 0
  name                   = "${var.name}-alb-requests"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.alb_request_label
    }

    target_value = var.alb_target_requests
  }
}
