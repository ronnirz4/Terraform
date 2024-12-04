# Lambda IAM Role
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

# Lambda Permissions Policy
resource "aws_iam_policy" "lambda_permissions" {
  name        = "LambdaPermissions"
  description = "Permissions for Lambda to interact with other services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "codepipeline:PutJobSuccessResult"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach Lambda Permissions Policy to Lambda IAM Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}

# Lambda Function for Code Validation
resource "aws_lambda_function" "validate_code" {
  filename         = "validate_code.zip"
  function_name    = "validate_code"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = filebase64sha256("validate_code.zip")
}

# Lambda Function for Running Tests
resource "aws_lambda_function" "run_tests" {
  filename         = "run_tests.zip"
  function_name    = "run_tests"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = filebase64sha256("run_tests.zip")
}
