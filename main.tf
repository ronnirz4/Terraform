# S3 Buckets for Artifact, Staging, and Production
resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "ronn4-artifact-bucket"
}

resource "aws_s3_bucket" "staging_bucket" {
  bucket = "ronn4-staging-bucket-unique"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "production_bucket" {
  bucket = "ronn4-production-bucket-unique"
}

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
        Resource = "arn:aws:s3:::ronn4-staging-bucket/*"
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
        Resource = "arn:aws:s3:::ronn4-production-bucket/*"
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "staging_lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role_main.name
  policy_arn = aws_iam_policy.staging_lambda_permissions.arn
}

resource "aws_iam_role_policy_attachment" "production_lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role_main.name
  policy_arn = aws_iam_policy.production_lambda_permissions.arn
}

# Create CodeBuild Service Role
resource "aws_iam_role" "codebuild_service_role" {
  name = "codebuild-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Effect    = "Allow"
      },
    ]
  })
}

# CodeBuild Policy for Permissions
resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild-policy"
  description = "Permissions for CodeBuild to access required resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::ronn4-artifact-bucket/*"
      },
      {
        Action   = ["sts:AssumeRole"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attach" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# Create CodeBuild Project
resource "aws_codebuild_project" "build" {
  name          = "serverless-app-build"
  description   = "Build Lambda functions for serverless app"
  build_timeout = "30"
  service_role  = aws_iam_role.codebuild_service_role.arn  # Use the new service role

  source {
    type     = "S3"
    location = "ronn4-staging-bucket/source.zip"
  }

  artifacts {
    type     = "S3"
    location = "ronn4-artifact-bucket"
  }

  environment {
    compute_type = "BUILD_GENERAL1_LARGE"
    image        = "aws/codebuild/standard:5.0"
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
# Create IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_service_role" {
  name = "codepipeline-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Effect    = "Allow"
      },
    ]
  })
}

# Create a policy that allows CodePipeline to assume the CodeDeploy role
resource "aws_iam_policy" "codepipeline_assume_codedeploy_role" {
  name        = "codepipeline-assume-codedeploy-role"
  description = "Policy to allow CodePipeline to assume CodeDeploy service role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = aws_iam_role.codedeploy_service_role.arn
      }
    ]
  })
}

# Attach the policy to the CodePipeline service role
resource "aws_iam_role_policy_attachment" "codepipeline_assume_codedeploy_role_attach" {
  role       = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_assume_codedeploy_role.arn
}

# S3 Permissions for CodePipeline Role (Read and Write)
resource "aws_iam_policy" "codepipeline_s3_access" {
  name        = "codepipeline-s3-access"
  description = "Permissions for CodePipeline to access the source and artifact buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::ronn4-staging-bucket/*",  # Source bucket
          "arn:aws:s3:::ronn4-artifact-bucket/*"  # Artifact bucket
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_s3_access_attach" {
  role       = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_s3_access.arn
}

# CodeBuild Permissions for CodePipeline Role
resource "aws_iam_policy" "codepipeline_codebuild_access" {
  name        = "codepipeline-codebuild-access"
  description = "Permissions for CodePipeline to interact with CodeBuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codebuild_access_attach" {
  role       = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_codebuild_access.arn
}

# CodeDeploy Permissions for CodePipeline Role
resource "aws_iam_policy" "codepipeline_codedeploy_access" {
  name        = "codepipeline-codedeploy-access"
  description = "Permissions for CodePipeline to interact with CodeDeploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:RegisterApplicationRevision"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_codedeploy_access_attach" {
  role       = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_codedeploy_access.arn
}

# Create CodePipeline
resource "aws_codepipeline" "pipeline" {
  name     = "serverless-app-pipeline"
  role_arn = aws_iam_role.codepipeline_service_role.arn  # Updated to use the new CodePipeline service role

  artifact_store {
    type     = "S3"
    location = "ronn4-artifact-bucket"
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
        S3Bucket    = "ronn4-staging-bucket"
        S3ObjectKey = "your-source-code.zip"
      }
      version = "1"
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
      version = "1"
    }
  }

  stage {
    name = "DeployStaging"
    action {
      name             = "DeployStagingAction"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeploy"
      input_artifacts  = ["BuildOutput"]
      configuration = {
        ApplicationName      = aws_codedeploy_app.app.name
        DeploymentGroupName  = aws_codedeploy_deployment_group.staging_deployment.deployment_group_name
      }
      version = "1"
    }
  }

  stage {
    name = "DeployProduction"
    action {
      name             = "DeployProductionAction"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeploy"
      input_artifacts  = ["BuildOutput"]
      configuration = {
        ApplicationName      = aws_codedeploy_app.app.name
        DeploymentGroupName  = aws_codedeploy_deployment_group.production_deployment.deployment_group_name
      }
      version = "1"
    }
  }
}
