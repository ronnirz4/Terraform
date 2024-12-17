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

# S3 Bucket Policy for Artifact Bucket
resource "aws_s3_bucket_object" "artifact_bucket_policy" {
  bucket = aws_s3_bucket.artifact_bucket.bucket
  key    = "artifact-bucket-policy.json"
  acl    = "private"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:*"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::ronn4-artifact-bucket/*"
        Principal = "*"
      }
    ]
  })
}

# S3 Bucket Policy for Staging Bucket
resource "aws_s3_bucket_object" "staging_bucket_policy" {
  bucket = aws_s3_bucket.staging_bucket.bucket
  key    = "staging-bucket-policy.json"
  acl    = "private"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:*"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::ronn4-staging-bucket-unique/*"
        Principal = "*"
      }
    ]
  })
}

# S3 Bucket Policy for Production Bucket
resource "aws_s3_bucket_object" "production_bucket_policy" {
  bucket = aws_s3_bucket.production_bucket.bucket
  key    = "production-bucket-policy.json"
  acl    = "private"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:*"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::ronn4-production-bucket-unique/*"
        Principal = "*"
      }
    ]
  })
}

# Create IAM Role for CodeDeploy Service with Full Access
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

# Attach full access policy to CodeDeploy role
resource "aws_iam_policy" "codedeploy_full_access" {
  name        = "codedeploy-full-access"
  description = "Full access for CodeDeploy to manage all resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_full_access_attach" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = aws_iam_policy.codedeploy_full_access.arn
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

# IAM Role for Lambda Functions with Full Access
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

# Attach full access policy to Lambda execution role
resource "aws_iam_policy" "lambda_full_access" {
  name        = "lambda-full-access"
  description = "Full access for Lambda to manage all resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_full_access_attach" {
  role       = aws_iam_role.lambda_exec_role_main.name
  policy_arn = aws_iam_policy.lambda_full_access.arn
}

# IAM Role for CodeBuild with Full Access
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

# Attach full access policy to CodeBuild role
resource "aws_iam_policy" "codebuild_full_access" {
  name        = "codebuild-full-access"
  description = "Full access for CodeBuild to manage all resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_full_access_attach" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_full_access.arn
}

# IAM Role for CodePipeline with Full Access
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

# Attach full access policy to CodePipeline role
resource "aws_iam_policy" "codepipeline_full_access" {
  name        = "codepipeline-full-access"
  description = "Full access for CodePipeline to manage all resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_full_access_attach" {
  role       = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_full_access.arn
}

# Create CodePipeline
resource "aws_codepipeline" "pipeline" {
  name     = "serverless-app-pipeline"
  role_arn = aws_iam_role.codepipeline_service_role.arn

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
        S3Bucket    = "ronn4-staging-bucket-unique"
        S3ObjectKey = "staging.zip"
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
