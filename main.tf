# Create CodeDeploy Application and Deployment Groups for Staging and Production
resource "aws_codedeploy_app" "app" {
  name = "my-serverless-app"
}

resource "aws_codedeploy_deployment_group" "staging_deployment" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "staging-deployment-group"
  service_role          = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
}

resource "aws_codedeploy_deployment_group" "production_deployment" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "production-deployment-group"
  service_role          = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
}

# Create IAM Role for CodeDeploy Service
resource "aws_iam_role" "codedeploy_service_role" {
  name = "codedeploy_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

# Attach necessary policies for CodeDeploy Service Role
resource "aws_iam_policy" "codedeploy_policy" {
  name        = "CodeDeployPermissions"
  description = "Permissions for CodeDeploy to manage deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attach" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = aws_iam_policy.codedeploy_policy.arn
}

# Step Functions State Machine Definition
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
