# EventBridge Scheduler
resource "aws_scheduler_schedule" "rotation" {
  name       = "${var.project_name}-rotation-schedule"
  group_name = "default"

  flexible_time_window {
    maximum_window_in_minutes = 15
    mode                      = "FLEXIBLE"
  }

  schedule_expression = var.rotation_schedule

  target {
    arn      = aws_lambda_function.rotation.arn
    role_arn = aws_iam_role.eventbridge.arn
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation.function_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.rotation.arn
}