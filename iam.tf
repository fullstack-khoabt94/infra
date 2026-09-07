# Identity provider
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# ECS execution role
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    sid = "ECSTrustedEntity"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_execution_secrets" {
  statement {
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.app_secret_arn,
      aws_db_instance.main.master_user_secret[0].secret_arn
    ]
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "tasklog-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "tasklog_ecs_execution_ecs" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "tasklog_ecs_getsecret" {
  name = "tasklog-ecs-getsecret"
  role = aws_iam_role.ecs_execution.id

  policy = data.aws_iam_policy_document.ecs_execution_secrets.json
}

resource "aws_iam_role" "ecs_task" {
  name               = "tasklog-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

# GHA deploy roles
data "aws_iam_policy_document" "app_deploy_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:fullstack-khoabt94@319339220/backend@1341488832:ref:refs/heads/main",
        "repo:fullstack-khoabt94@319339220/frontend@1341447804:ref:refs/heads/main"
      ]
    }
  }
}

data "aws_iam_policy_document" "app_deploy" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [
      data.aws_ecr_repository.backend.arn,
      data.aws_ecr_repository.frontend.arn
    ]
  }

  statement {
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:TagResource"
    ]
    resources = ["*"]
  }

  statement {
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.ecs_execution.arn,
      aws_iam_role.ecs_task.arn
    ]
  }
}

resource "aws_iam_role" "app_deploy" {
  name               = "tasklog-app-deploy"
  assume_role_policy = data.aws_iam_policy_document.app_deploy_trust.json
}

resource "aws_iam_role_policy" "app_deploy" {
  name = "tasklog-app-deploy"
  role = aws_iam_role.app_deploy.id

  policy = data.aws_iam_policy_document.app_deploy.json
}

# Infra deploy role
data "aws_iam_policy_document" "infra_deploy_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:fullstack-khoabt94@319339220/infra@1354285492:ref:refs/heads/main",
      ]
    }
  }
}

data "aws_iam_policy_document" "admin_access" {
  statement {
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "infra_deploy" {
  name               = "tasklog-infra-deploy"
  assume_role_policy = data.aws_iam_policy_document.infra_deploy_trust.json
}

resource "aws_iam_role_policy" "infra_deploy" {
  name = "tasklog-infra-deploy"
  role = aws_iam_role.infra_deploy.id

  policy = data.aws_iam_policy_document.admin_access.json
}
