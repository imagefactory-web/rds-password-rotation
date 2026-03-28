# Package Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda.zip"
}

# Lambda Function
resource "aws_lambda_function" "rotation" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-password-rotation"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 300
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      RDS_INSTANCE_ID    = aws_db_instance.main.identifier
      RDS_USERNAME       = var.rds_master_username
      SSM_PARAMETER_PATH = "/${var.project_name}/rds-password"
    }
  }
}