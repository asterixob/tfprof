output "api_url" {
  description = "the api url"
  value = aws_apigatewayv2_stage.lambda.invoke_url
  }