
# ALB SG
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "ALB - HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Task SG
resource "aws_security_group" "task_sg" {
  name        = "task-sg"
  description = "ECS task - 8080 from ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "task-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "task_alb" {
  security_group_id            = aws_security_group.task_sg.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "task_all" {
  security_group_id = aws_security_group.task_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# RDS SG
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "RDS - 5432 from ECS task"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_task" {
  security_group_id            = aws_security_group.rds_sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.task_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_public" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}
