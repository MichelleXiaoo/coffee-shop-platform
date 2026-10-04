# Notification channel. The email subscription must be confirmed by clicking
# the link AWS sends - Terraform cannot confirm it for you.
resource "aws_sns_topic" "alerts" {
  name = "${var.name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Sustained high CPU. Catches runaway processes and undersized instances.
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpu-high"
  alarm_description   = "Average CPU above ${var.cpu_threshold}% for 5 minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.cpu_threshold
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  # Do not alarm when there is simply no data yet (fresh instance).
  treat_missing_data = "notBreaching"
}

# Instance or hypervisor health. This is the one Prometheus CANNOT report,
# because if the instance is gone, Prometheus is gone with it.
resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name          = "${var.name}-status-check-failed"
  alarm_description   = "EC2 instance or system status check failing"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]
  treat_missing_data = "notBreaching"
}