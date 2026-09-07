resource "aws_db_instance" "main" {
  allocated_storage = 20
  identifier        = "tasklog"
  db_name           = "tasklog"
  engine            = "postgres"
  engine_version    = "17.5"
  instance_class    = "db.t3.micro"
  storage_type      = "gp3"
  storage_encrypted = true


  username                    = "tasklog_admin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.rds.name
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
  publicly_accessible         = true

  multi_az                = false
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"] # = AMI 64-bit (Arm)
  }
}
