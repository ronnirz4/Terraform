# Provider Configuration
provider "aws" {
  region = "us-east-2"
}

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

# Step Functions Permissions Policy
resource "aws_iam_policy" "step_functions_permissions" {
  name        = "StepFunctionsPermissions"
  description = "Permissions for Step Functions to execute Lambda and CodeDeploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["codedeploy:CreateDeployment", "codedeploy:GetDeployment"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to Step Functions IAM Role
resource "aws_iam_role_policy_attachment" "step_functions_policy_attach" {
  role       = aws_iam_role.step_functions_execution_role.name
  policy_arn = aws_iam_policy.step_functions_permissions.arn
}

# Create CodeDeploy Application and Deployment Group for Staging and Production
resource "aws_codedeploy_app" "app" {
  name = "my-serverless-app"
}

resource "aws_codedeploy_deployment_group" "staging_deployment" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "staging-deployment-group"
  service_role          = aws_iam_role.step_functions_execution_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
}

resource "aws_codedeploy_deployment_group" "production_deployment" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "production-deployment-group"
  service_role          = aws_iam_role.step_functions_execution_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
}

# Step Functions State Machine for Multi-stage Deployment
resource "aws_sfn_state_machine" "deployment" {
  name     = "DeploymentStateMachine"
  role_arn = aws_iam_role.step_functions_execution_role.arn

  definition = jsonencode({
    StartAt = "ValidateCode",
    States = {
      ValidateCode = {
        Type    = "Task"
        Resource = aws_lambda_function.validate_code.arn
        Next     = "DeployToStaging"
      },
      DeployToStaging = {
        Type    = "Task"
        Resource = aws_codedeploy_deployment_group.staging_deployment.arn
        Next     = "RunTests"
      },
      RunTests = {
        Type    = "Task"
        Resource = aws_lambda_function.run_tests.arn
        Next     = "PromoteToProduction"
      },
      PromoteToProduction = {
        Type    = "Task"
        Resource = aws_codedeploy_deployment_group.production_deployment.arn
        End     = true
      }
    }
  })
}

# Output the State Machine ARN
output "state_machine_arn" {
  value = aws_sfn_state_machine.deployment.arn
}
