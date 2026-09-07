output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "url" {
  value = "https://app.khoatienbui94.click"
}

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_master_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "app_secret_arn" {
  value = var.app_secret_arn
}

output "backend_repository_url" {
  value = data.aws_ecr_repository.backend.repository_url
}

output "frontend_repository_url" {
  value = data.aws_ecr_repository.frontend.repository_url
}

output "app_deploy_role_arn" {
  value = aws_iam_role.app_deploy.arn
}

output "infra_deploy_role_arn" {
  value = aws_iam_role.infra_deploy.arn
}
