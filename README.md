# Ron's Final Project step function with Terraform using AWS 

 Step Functions is a visual workflow service that helps developers use AWS services to build distributed applications, automate processes, orchestrate microservices, and create data and machine learning pipelines .


# Continuous Deployment Pipeline for Serverless Applications

This document outlines how to build a CI/CD pipeline for deploying serverless applications using AWS Step Functions, Lambda, CodeDeploy, and Terraform.

## Goal:
Design a Step Function that orchestrates a multi-stage deployment process for serverless applications.

## Pipeline Stages:

1. **Code Commit**  
   The process starts with a code commit in your repository (e.g., GitHub, GitLab). This triggers the deployment pipeline.

2. **CodePipeline**  
   AWS CodePipeline orchestrates the pipeline. It is triggered by the code commit and initiates the following steps:

3. **Lambda - Validate Code**  
   A Lambda function validates the code. If validation fails, the process stops and the issue is flagged.  
   If the code is valid, it moves to the next stage.

4. **AWS CodeDeploy - Deploy to Staging**  
   CodeDeploy is used to deploy the application to the staging environment. This includes version management and deployment tracking.

5. **Automated Tests**  
   Automated tests are run using Lambda or another test automation tool.  
   - If tests pass, the pipeline proceeds to the next stage.
   - If tests fail, the pipeline will either stop or trigger a rollback.

6. **Step Functions - Conditional Logic**  
   AWS Step Functions manage the flow of tasks in the pipeline.  
   - If the tests pass, the application will be promoted to production.
   - If tests fail, a rollback will be triggered to revert the changes.

7. **Lambda - Rollback**  
   If a failure occurs at any stage, a Lambda function will perform the rollback and restore the application to its previous stable state.

8. **AWS CodeDeploy - Deploy to Production**  
   Once all tests pass and the staging deployment is successful, the application is deployed to production using CodeDeploy.

9. **Success**  
   The pipeline ends with a success message after the production deployment completes successfully.

---

## Terraform Infrastructure

Use **Terraform** to define the following infrastructure components:

- **CodePipeline**
- **CodeDeploy**
- **Lambda Functions** (for validation, testing, and rollback)
- **Step Functions** (for orchestrating the deployment process)

You can use **Terraform Cloud** or **Jenkins** to automate the deployment of this infrastructure.

---

## Rollback Functionality

In case of deployment failure, the pipeline will automatically trigger a rollback:

1. **Step Functions** will detect test failures.
2. A **Lambda function** will be invoked to rollback the deployment to a stable state.

This ensures that the production environment is always in a healthy state, even if issues occur during deployment.

---

## Example Diagram (ASCII)

Below is a simple text-based diagram showing the steps in the pipeline:

+-------------------+
|  Code Commit      |
+-------------------+
        |
        v
+-------------------+               +-------------------+
|  CodePipeline     |  Triggered    |   Lambda (Validate)|
+-------------------+   on commit   +-------------------+
        |
        v
+-------------------+               +-------------------+
|  Lambda (Validate)|               |  AWS CodeDeploy   |
|  Validate Code    |  Success      |  Deploy to Staging|
+-------------------+               +-------------------+
        |
        v
+-------------------+               +-------------------+
| Automated Tests   |  Pass/Fail    |  Lambda (Test)    |
| Run Tests         |  Test Results |  Automated Testing |
+-------------------+               +-------------------+
        |
        v
+-------------------+      Success/Failure    +-------------------+
|  Step Function    |  ---------------------> |  Step Function    |
|  Conditional Logic|        Rollback?         |  Promote to Prod  |
+-------------------+                        +-------------------+
        |                                          |
        v                                          v
+-------------------+               +-------------------+
|  Lambda (Rollback)|               |  AWS CodeDeploy   |
|  Rollback if Fail |               |  Deploy to Prod   |
+-------------------+               +-------------------+
        |
        v
+-------------------+
|    Success        |
+-------------------+


Serverless CI/CD Pipeline Overview

This repository demonstrates the use of AWS services (S3, CodeDeploy, CodeBuild, CodePipeline) to automate the deployment of a serverless application. The pipeline is managed using Terraform, and it consists of multiple components: the Main File, Lambda File, and Step Function File.

Components Overview

1. Main File
The Main File (main.tf) is the backbone of the entire infrastructure. It defines and provisions the AWS resources needed to support the CI/CD pipeline. These resources include S3 Buckets, IAM Roles and Policies, CodeDeploy, CodeBuild, and CodePipeline.
It sets up the environment for the serverless app to run, configures the necessary IAM permissions, and ties together all other components like the Lambda function and Step Functions for orchestration.
2. Lambda File
The Lambda File (lambda.tf) contains the configuration for AWS Lambda functions that are part of the CI/CD pipeline. These Lambda functions may perform specific tasks such as validating code, running tests, or handling rollback operations during deployment.
Lambda functions provide the compute logic that is invoked during the pipeline stages (for example, in CodeBuild or CodeDeploy) to ensure that the application behaves as expected.
3. Step Function File
The Step Function File (step-functions.tf) is where AWS Step Functions are configured to orchestrate and manage the workflow of the deployment pipeline.
It coordinates the different tasks defined in the pipeline, such as invoking Lambda functions for validation, testing, or rollback, and deciding whether to promote the app to production based on test results.
It provides error handling and decision-making logic to ensure that the pipeline runs smoothly and rolls back if something goes wrong.
Main File Breakdown

The Main File (main.tf) is the central configuration point for the Terraform deployment. It defines the AWS resources required for the serverless application CI/CD pipeline, such as:

Key Components Defined in the Main File:
S3 Buckets for Artifact, Staging, and Production
Artifact Bucket: Stores the build artifacts generated during the CodeBuild process.
Staging Bucket: Holds the staging version of the app for testing before production deployment.
Production Bucket: Stores the final production version of the application.
IAM Roles and Policies
Defines various IAM roles for services like CodePipeline, CodeDeploy, Lambda, and CodeBuild, and attaches the necessary policies for these services to interact securely.
CodeDeploy Setup
Creates a CodeDeploy application and defines Deployment Groups for staging and production. This ensures that the application can be deployed to different environments based on pipeline stages.
CodeBuild Project
Configures a CodeBuild project to build the Lambda functions. The output artifacts are stored in the Artifact Bucket for use in later stages of the pipeline.
CodePipeline Setup
Creates a CodePipeline that automates the entire CI/CD process, including source retrieval (from S3), build (via CodeBuild), and deployment (via CodeDeploy) to both staging and production environments.
Example of Main File Workflow:

S3 Buckets are created for storing build artifacts, staging files, and production files.
IAM Roles and Policies are set up to ensure that the pipeline services can interact with each other securely.
A CodeDeploy Application is created for both staging and production environments.
A CodeBuild Project is defined to automate the build process, using source code stored in the Staging Bucket and outputting the build artifacts to the Artifact Bucket.
A CodePipeline is configured to:
Pull the source from the Staging Bucket.
Trigger the CodeBuild Project to build the application.
Deploy to Staging via CodeDeploy.
Deploy to Production via CodeDeploy once the staging deployment is successful.


Components of the Step Function File

1. Step Function State Machine
The AWS Step Function State Machine is created using the aws_sfn_state_machine resource. This defines the sequence of tasks that need to be executed in order, each linked to a specific Lambda function or CodeDeploy action.

2. States in the State Machine
The state machine is configured to follow this sequence of steps:

1. ValidateCode

Type: Task
Resource: Lambda function validate_code
Description: This step invokes the Lambda function to validate the application code. The validation could include tasks like checking the syntax or performing static analysis on the code.
Next: If validation passes, it proceeds to the RunTests state.
2. RunTests

Type: Task
Resource: Lambda function run_tests
Description: This Lambda function runs automated tests against the code to ensure that everything behaves as expected.
Next: If tests pass, it proceeds to deploy to the Staging environment.
3. DeployStaging

Type: Task
Resource: CodeDeploy staging_deployment
Description: This state triggers the deployment to the Staging Environment using AWS CodeDeploy. CodeDeploy ensures that the application is properly deployed to staging.
Next: Once the staging deployment completes, it moves to the RunTestsInStaging state.
4. RunTestsInStaging

Type: Task
Resource: Lambda function run_tests
Description: After deploying to staging, this Lambda function runs tests in the staging environment to verify that the application works as expected in a more production-like environment.
Next: If tests pass in staging, it proceeds to deploy to Production.
5. DeployProduction

Type: Task
Resource: CodeDeploy production_deployment
Description: This state triggers the deployment to the Production Environment using AWS CodeDeploy.
End: The state machine ends after deploying to production.
Key Components in the Step Function File:

Step Function State Machine:
The state machine is named DeploymentStateMachine, and it is linked to a Step Functions Execution Role (aws_iam_role.step_functions_execution_role), which allows Step Functions to execute tasks on other AWS services.
Task States:
Each step in the workflow is defined as a Task in the state machine, which is a specific type of state that invokes a service such as Lambda or CodeDeploy.
Transitions:
After each task, the workflow proceeds to the next step (Next), except for the last task (DeployProduction), where the process ends (End).
Lambda and CodeDeploy Integration:
The state machine invokes Lambda functions for code validation and running tests.
CodeDeploy is used for deploying the application to staging and production environments.
Example Workflow:

Here’s the flow of the Step Functions in a simple diagram:

+-------------------+        +-------------------+      +-------------------+  
|  ValidateCode     | ---->  |  RunTests         | ---> | DeployStaging     |  
|  (Lambda)         |        |  (Lambda)         |      |  (CodeDeploy)     |  
+-------------------+        +-------------------+      +-------------------+  
                                                              |
                                                              v
                                                   +-------------------+  
                                                   | RunTestsInStaging |  
                                                   |   (Lambda)        |  
                                                   +-------------------+
                                                              |
                                                              v
                                                   +-------------------+  
                                                   | DeployProduction  |  
                                                   |  (CodeDeploy)     |  
                                                   +-------------------+  
Main Role of the Step Function File:

The Step Function File serves as the orchestrator for the deployment process, ensuring that each stage (validation, testing, deployment to staging, testing in staging, and production deployment) is executed in sequence. It ensures that:

Code is validated before deployment.
Automated tests are run at multiple stages (before and after staging deployment).
The app is first deployed to Staging, tested, and then deployed to Production if all tests pass.
The state machine handles the decision-making process and flow control, ensuring the deployment process is smooth and follows the correct order.

Key Components of the Lambda File:

1. IAM Role for Step Functions Execution
This IAM Role (step_functions_execution_role) allows AWS Step Functions to execute tasks on your behalf. It gives Step Functions the necessary permissions to invoke Lambda functions and interact with CodeDeploy.

resource "aws_iam_role" "step_functions_execution_role" {
  name = "step_functions_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "states.amazonaws.com" }
        Effect    = "Allow"
      }
    ]
  })
}
2. IAM Role for Lambda Execution
This IAM Role (lambda_exec_role_lambda) is used by the Lambda functions. It provides permissions to execute the Lambda functions and interact with AWS resources (such as S3, CodePipeline, IAM roles, etc.).

resource "aws_iam_role" "lambda_exec_role_lambda" {
  name = "lambda_exec_role_lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "lambda.amazonaws.com" }
        Effect    = "Allow"
      }
    ]
  })
}
3. Lambda Permissions Policy
The Lambda Permissions Policy grants permissions to Lambda functions to interact with AWS resources such as S3, CodePipeline, and CodeDeploy. This ensures that Lambda functions can access and update these services.

resource "aws_iam_policy" "lambda_permissions" {
  name        = "LambdaPermissions"
  description = "Permissions for Lambda to interact with other services"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::ronn4-staging-bucket-unique/*"
      },
      {
        Action   = ["codepipeline:PutJobSuccessResult"]
        Effect   = "Allow"
        Resource = "arn:aws:codepipeline:us-east-2:023196572641:serverless-app-pipeline"
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
4. Lambda Functions
The Lambda functions defined here are used to carry out tasks in the deployment pipeline. Each Lambda function is defined with a role, handler, and runtime (Node.js 18.x in this case).

- validate_code Lambda:

This function is used to validate the code before it gets deployed. It might check for syntax errors, missing dependencies, or other code quality issues.

resource "aws_lambda_function" "validate_code" {
  filename         = "validate_code.zip"
  function_name    = "validate_code"
  role             = aws_iam_role.lambda_exec_role_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("validate_code.zip")
}
- run_tests Lambda:

This function runs automated tests on the code. It could involve unit tests, integration tests, or any other test suite you use to verify the correctness of the application.

resource "aws_lambda_function" "run_tests" {
  filename         = "RunTests.zip"
  function_name    = "run_tests"
  role             = aws_iam_role.lambda_exec_role_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("RunTests.zip")
}
- staging Lambda:

This Lambda function could be used to deploy or prepare the application in the Staging Environment.

resource "aws_lambda_function" "staging" {
  filename         = "staging.zip"
  function_name    = "staging"
  role             = aws_iam_role.lambda_exec_role_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("staging.zip")
}
- production Lambda:

Similar to the staging function, this Lambda function is responsible for deploying the application in the Production Environment.

resource "aws_lambda_function" "production" {
  filename         = "production.zip"
  function_name    = "production"
  role             = aws_iam_role.lambda_exec_role_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("production.zip")
}
5. Step Functions Permissions Policy
The Step Functions Permissions Policy allows Step Functions to invoke Lambda functions and interact with CodeDeploy to handle deployments. This policy is attached to the Step Functions Execution Role defined earlier.

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
Role of the Lambda File in the Pipeline

The Lambda File is crucial to the pipeline because it:

Defines the Lambda functions that are invoked at different stages of the Step Function workflow.
Grants necessary IAM permissions to ensure that Lambda functions can interact with other services like S3, CodePipeline, and CodeDeploy.
Ensures that Step Functions can execute these Lambda functions and trigger deployments in Staging and Production environments.
How It Connects to Other Files:
Main File (main.tf): The Main File provisions the infrastructure resources needed by Lambda, Step Functions, and CodeDeploy. It creates the necessary S3 buckets, IAM roles, and other resources.
Step Function File (step-functions.tf): The Step Function File orchestrates the execution flow by calling these Lambda functions in the proper sequence.
Lambda File (lambda.tf): The Lambda File defines the logic for code validation, test execution, and deployments in staging and production.
Example Workflow:

Here’s how the Lambda functions tie into the Step Function workflow:

ValidateCode: The Step Function invokes the validate_code Lambda function to validate the code before deployment.
RunTests: The run_tests Lambda function runs tests after validation.
DeployStaging: Deploys to Staging using CodeDeploy (not a Lambda task, but part of the Step Function).
RunTestsInStaging: After deployment to staging, the run_tests Lambda runs again to test the staging environment.
DeployProduction: Finally, the application is deployed to Production using CodeDeploy.