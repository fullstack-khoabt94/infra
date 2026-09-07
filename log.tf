resource "aws_cloudwatch_log_group" "backend" {
  name = "/ecs/tasklog-backend"

  retention_in_days = 5
}

resource "aws_cloudwatch_log_group" "frontend" {
  name = "/ecs/tasklog-frontend"

  retention_in_days = 5
}
