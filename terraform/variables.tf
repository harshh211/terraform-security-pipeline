variable "aws_account_id" {
  description = "AWS account ID used to scope IAM trust and resource policies"
  type        = string
  default     = "123456789012"
}

variable "db_password" {
  description = "RDS master password — supplied via -var or TF_VAR_db_password, never committed"
  type        = string
  sensitive   = true
}
