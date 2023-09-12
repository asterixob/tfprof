# main.tf

# quick hack to ensure nodejs depency added. Should be part of another pipline which builds,tests and packages functions
resource "null_resource" "lambda_deps" {
    provisioner "local-exec" {
        command = <<EOT
        pushd lambdas/lambda-add-item
        npm install aws-sdk
        popd
        pushd lambdas/lambda-retrieve-count
        npm install aws-sdk
        popd
EOT
    }
  triggers = {
    always_run = "${timestamp()}"
  }
}


# Create zip file of our lambdas
data "archive_file" "lambda-add-item" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/lambda-add-item"
  output_path = "${path.module}/lambdas/lambda-add-item/lambda-add-item.zip"
  depends_on = [ null_resource.lambda_deps ]
}

data "archive_file" "lambda-retrieve-count" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/lambda-retrieve-count"
  output_path = "${path.module}/lambdas/lambda-retrieve-count/lambda-retrieve-count.zip"
  depends_on = [ null_resource.lambda_deps ]
}


# Create lambda functions
resource "aws_lambda_function" "calculate_occurrences_lambda" {
  function_name = "calculate-occurrences-lambda"
  handler      = "lambda-add-item.handler"
  runtime      = "nodejs16.x"
  filename     = data.archive_file.lambda-add-item.output_path
  role         = aws_iam_role.lambda_exec.arn
  source_code_hash = data.archive_file.lambda-add-item.output_base64sha256
  timeout      = 10 # Adjust as needed
  depends_on = [ aws_iam_role.lambda_exec ]
}

resource "aws_lambda_function" "retrieve_occurrences_lambda" {
  function_name = "retrieve-occurrences-lambda"
  handler      = "lambda-retrieve-count.handler"
  runtime      = "nodejs16.x"
  filename     = data.archive_file.lambda-retrieve-count.output_path 
  role         = aws_iam_role.lambda_exec.arn
  source_code_hash = data.archive_file.lambda-retrieve-count.output_base64sha256
  timeout      = 10 # Adjust as needed
  depends_on = [ aws_iam_role.lambda_exec ]

}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Attach dynamo policy to the IAM role
resource "aws_iam_policy_attachment" "dynamodb_get_put_access_attachment" {
  name = "dynamodb-get-put-access-attachment"
  policy_arn = aws_iam_policy.dynamoDBLambdaPolicy.arn
  roles = [aws_iam_role.lambda_exec.name]
}


# Create a CloudWatch log group for Lambda function logs
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/logs"
  retention_in_days = 7 # Adjust retention as needed
}

# Attach the Lambda function's execution role to the log group
resource "aws_iam_policy_attachment" "lambda_log_group_attachment" {
  name = "lambda_log"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles      = [aws_iam_role.lambda_exec.name]
}


# Create API GW using v2
resource "aws_apigatewayv2_api" "lambda" {
  name = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

# Create Proxy integration for route /calculate-number-of-occurrences
resource "aws_apigatewayv2_integration" "count" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.calculate_occurrences_lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "count" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /calculate-number-of-occurrences"
  target    = "integrations/${aws_apigatewayv2_integration.count.id}"
}

# Create Proxy integration for route /get-number-of-occurrences/{itemId}
resource "aws_apigatewayv2_integration" "occurrences" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.retrieve_occurrences_lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}


resource "aws_apigatewayv2_route" "occurrences" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /get-number-of-occurrences/{itemId}"
  target    = "integrations/${aws_apigatewayv2_integration.occurrences.id}"
}


resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 7
}

# Allow lambdas to be called from api gw
resource "aws_lambda_permission" "api_gw_count" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calculate_occurrences_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
  
}

resource "aws_lambda_permission" "api_gw_occurrence" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.retrieve_occurrences_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
  
}


