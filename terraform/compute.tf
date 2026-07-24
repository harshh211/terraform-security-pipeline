resource "aws_instance" "app_server" {
  ami                         = "ami-0c55b159cbfafe1f0"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.app_server.name
  monitoring                  = true
  ebs_optimized                = true

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens = "required"
  }
}

resource "aws_db_instance" "app_db" {
  identifier                          = "app-database"
  engine                               = "mysql"
  instance_class                       = "db.t3.micro"
  allocated_storage                    = 20
  username                             = "admin"
  password                             = var.db_password
  storage_encrypted                    = true
  publicly_accessible                  = false
  skip_final_snapshot                  = true
  iam_database_authentication_enabled  = true
  deletion_protection                  = true
  multi_az                             = true
  auto_minor_version_upgrade           = true
  copy_tags_to_snapshot                = true
  enabled_cloudwatch_logs_exports      = ["error", "general", "slowquery"]
  monitoring_interval                  = 60
  monitoring_role_arn                  = aws_iam_role.rds_monitoring.arn
}
