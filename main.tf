# Create IAM Role for CodeDeploy Service
resource "aws_iam_role" "codedeploy_service_role" {
  name = "codedeploy-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Effect    = "Allow"
      },
    ]
  })
}

# Create CodeDeploy Application and Deployment Groups for Staging and Production
resource "aws_codedeploy_app" "app" {
  name = "my-serverless-app"
}

resource "aws_codedeploy_deployment_group" "staging_deployment" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "staging-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
}

resource "aws_codedeploy_deployment_group" "production_deployment" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "production-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
}

# Attach necessary policies for CodeDeploy Service Role
resource "aws_iam_policy" "codedeploy_policy" {
  name        = "codedeploy-permissions"
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

# Create IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_exec_role_main" {
  name = "lambda-execution-role_main"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect    = "Allow"
      },
    ]
  })
}

# Lambda Permissions Policy for Staging and Production Functions
resource "aws_iam_policy" "staging_lambda_permissions" {
  name        = "staging-lambda-permissions"
  description = "Permissions for Staging Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::your-bucket-name/*"  # Update with actual bucket
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "production_lambda_permissions" {
  name        = "production-lambda-permissions"
  description = "Permissions for Production Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::your-bucket-name/*"  # Update with actual bucket
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach Staging Lambda Permissions Policy to Staging Lambda IAM Role
resource "aws_iam_role_policy_attachment" "staging_lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role_main.name
  policy_arn = aws_iam_policy.staging_lambda_permissions.arn
}

# Attach Production Lambda Permissions Policy to Production Lambda IAM Role
resource "aws_iam_role_policy_attachment" "production_lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role_main.name
  policy_arn = aws_iam_policy.production_lambda_permissions.arn
}

# Create Staging Lambda Function
resource "aws_lambda_function" "staging_function" {
  filename         = "staging.zip"
  function_name    = "staging-function"
  role             = aws_iam_role.lambda_exec_role_main.arn  # Corrected reference
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("staging.zip")
}

# Create Production Lambda Function
resource "aws_lambda_function" "production_function" {
  filename         = "production.zip"
  function_name    = "production-function"
  role             = aws_iam_role.lambda_exec_role_main.arn  # Corrected reference
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("production.zip")
}

# Create Lambda Functions for Validation and Running Tests
resource "aws_lambda_function" "validate_code_function" {
  filename         = "validate_code.zip"
  function_name    = "validate-code-function"
  role             = aws_iam_role.lambda_exec_role_main.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("validate_code.zip")
}

resource "aws_lambda_function" "run_tests_function" {
  filename         = "run_tests.zip"
  function_name    = "run-tests-function"
  role             = aws_iam_role.lambda_exec_role_main.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("run_tests.zip")
}

resource "aws_codebuild_project" "build" {
  name          = "serverless-app-build"
  description   = "Build Lambda functions for serverless app"
  build_timeout = "30"
  service_role  = aws_iam_role.lambda_exec_role_main.arn

  source {
    type     = "S3"
    location = "ronn4-production-bucket/production.zip"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:18.x"
    type         = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = "CodeBuildLogs"
      stream_name = "BuildStream"
    }
  }
}

# Create CodePipeline
resource "aws_codepipeline" "pipeline" {
  name     = "serverless-app-pipeline"
  role_arn = aws_iam_role.codedeploy_service_role.arn

  artifact_store {
    type     = "S3"
    location = "ronn4-production-bucket"  # Using production bucket for build artifacts
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      output_artifacts = ["SourceOutput"]
      configuration = {
        S3Bucket    = "ronn4-staging-bucket"  # Using staging bucket for the source code
        S3ObjectKey = "your-source-code.zip"  # Replace with your actual object key
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "DeployToStaging"
    action {
      name             = "DeployToStagingAction"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeploy"
      input_artifacts  = ["BuildOutput"]
      configuration = {
        ApplicationName      = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.staging_deployment.deployment_group_name
      }
    }
  }

  stage {
    name = "RunTests"
    action {
      name             = "RunTestsAction"
      category         = "Invoke"
      owner            = "AWS"
      provider         = "Lambda"
      input_artifacts  = ["BuildOutput"]
      configuration = {
        FunctionName = aws_lambda_function.run_tests_function.function_name
      }
    }
  }

  stage {
    name = "DeployToProduction"
    action {
      name             = "DeployToProductionAction"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeploy"
      input_artifacts  = ["BuildOutput"]
      configuration = {
        ApplicationName      = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.production_deployment.deployment_group_name
      }
    }
  }
}
