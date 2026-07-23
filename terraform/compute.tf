resource "aws_instance" "app_server" {
  ami                         = "ami-0c55b159cbfafe1f0"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  root_block_device {
    encrypted = false
  }

  metadata_options {
    http_tokens = "optional"
  }
}

resource "aws_db_instance" "app_db" {
  identifier          = "app-database"
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "admin"
  password            = "SuperSecret123!"
  storage_encrypted   = false
  publicly_accessible = true
  skip_final_snapshot = true
}
