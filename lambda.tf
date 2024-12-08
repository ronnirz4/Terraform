# Create IAM Role for Step Functions Execution
resource "aws_iam_role" "step_functions_execution_role" {
  name = "step_functions_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

# Create Lambda Execution Role
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

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
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::your-bucket-name/*"
      },
      {
        Action   = ["codepipeline:PutJobSuccessResult"]
        Effect   = "Allow"
        Resource = "arn:aws:codepipeline:us-east-2:123456789012:your-pipeline-name"
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
  filename         = "RunTests.zip"
  function_name    = "run_tests"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = filebase64sha256("RunTests.zip")
}

# Step Functions Permissions Policy (referencing Lambda functions now)
resource "aws_iam_policy" "step_functions_permissions" {
  name        = "StepFunctionsPermissions"
  description = "Permissions for Step Functions to execute Lambda and CodeDeploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = [
          aws_lambda_function.validate_code.arn,
          aws_lambda_function.run_tests.arn
        ]
      },
      {
        Action   = ["codedeploy:CreateDeployment", "codedeploy:GetDeployment"]
        Effect   = "Allow"
        Resource = [
          aws_codedeploy_app.app.arn,
          aws_codedeploy_deployment_group.staging_deployment.arn,
          aws_codedeploy_deployment_group.production_deployment.arn
        ]
      }
    ]
  })
}

# Attach Policy to Step Functions IAM Role
resource "aws_iam_role_policy_attachment" "step_functions_policy_attach" {
  role       = aws_iam_role.step_functions_execution_role.name
  policy_arn = aws_iam_policy.step_functions_permissions.arn
}
