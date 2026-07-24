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

variable "ci_trusted_role_name" {
  description = "Name of the specific IAM role permitted to assume ci_role (avoids trusting the whole account root)"
  type        = string
  default     = "github-actions-deployer"
}
