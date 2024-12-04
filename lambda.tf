resource "aws_lambda_function" "validate_code" {
  filename         = "validate_code.zip"
  function_name    = "validate_code"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"

  source_code_hash = filebase64sha256("validate_code.zip")
}

resource "aws_lambda_function" "run_tests" {
  filename         = "run_tests.zip"
  function_name    = "run_tests"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"

  source_code_hash = filebase64sha256("run_tests.zip")
}
