resource "aws_iam_role" "app_role" {
  name = "app-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "app_policy" {
  name = "app-service-policy"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "ci_role" {
  name = "ci-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = "*" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ci_policy" {
  name = "ci-deploy-policy"
  role = aws_iam_role.ci_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:CreatePolicyVersion",
        "iam:AttachRolePolicy",
        "iam:PassRole"
      ]
      Resource = "*"
    }]
  })
}
