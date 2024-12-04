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
