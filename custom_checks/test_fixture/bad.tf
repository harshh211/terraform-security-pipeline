resource "aws_db_instance" "test" {
  identifier = "test-db"
  engine     = "mysql"
  username   = "admin"
  password   = "HardcodedPassword1!"
}
