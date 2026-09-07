data "aws_ecr_repository" "backend" {
  name = "tasklog/backend"
}

data "aws_ecr_repository" "frontend" {
  name = "tasklog/frontend"
}

resource "aws_ecs_cluster" "main" {
  name = "tasklog"
}

# Task
resource "aws_ecs_task_definition" "backend" {
  family                   = "tasklog-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${data.aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_URL"
          value = "jdbc:postgresql://${aws_db_instance.main.endpoint}/tasklog"
        },
      ]
      secrets = [
        {
          name      = "JWT_SECRET"
          valueFrom = "${var.app_secret_arn}:jwt::"
        },
        {
          name      = "REFRESH_TOKEN_SECRET"
          valueFrom = "${var.app_secret_arn}:refresh::"
        },
        {
          name      = "POSTGRES_USER"
          valueFrom = "${aws_db_instance.main.master_user_secret[0].secret_arn}:username::"
        },
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${aws_db_instance.main.master_user_secret[0].secret_arn}:password::"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "tasklog-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${data.aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Service
resource "aws_ecs_service" "backend" {
  name            = "tasklog-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    assign_public_ip = true
    subnets = [
      aws_subnet.public_0.id,
      aws_subnet.public_1.id
    ]
    security_groups = [aws_security_group.task_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8080
  }

  health_check_grace_period_seconds = 180

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener_rule.backend_forward]
}

resource "aws_ecs_service" "frontend" {
  name            = "tasklog-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    assign_public_ip = true
    subnets = [
      aws_subnet.public_0.id,
      aws_subnet.public_1.id
    ]
    security_groups = [aws_security_group.task_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 8080
  }

  health_check_grace_period_seconds = 180

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.https]
}

