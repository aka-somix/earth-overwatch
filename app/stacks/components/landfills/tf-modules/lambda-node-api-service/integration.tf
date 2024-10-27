#
# --- LAMBDA PERMISSION POLICY FOR APIGW
#
resource "aws_lambda_permission" "allow_api_gateway" {
  function_name = aws_lambda_function.this.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.apigw_rest_api.execution_arn}/*/*/*"

  depends_on = [
    aws_api_gateway_resource.this
  ]
}

#
# -- APIGW INTEGRATION RESOURCE --
# Needed to call lambda endpoint 

resource "aws_api_gateway_resource" "this" {
  rest_api_id = var.apigw_rest_api.id
  parent_id   = var.apigw_rest_api.root_resource_id
  path_part   = var.lambda_service_resource_path
}

resource "aws_api_gateway_method" "any_this" {
  rest_api_id      = var.apigw_rest_api.id
  resource_id      = aws_api_gateway_resource.this.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id = var.apigw_rest_api.id
  resource_id = aws_api_gateway_method.any_this.resource_id
  http_method = aws_api_gateway_method.any_this.http_method
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.this.invoke_arn

  # AWS lambdas can only be invoked with the POST method
  integration_http_method = "POST"
}

#
# -- PROXY RESOURCE --
# Proxies everything after /data-service/* to the lambda function

resource "aws_api_gateway_resource" "this_proxy" {
  rest_api_id = var.apigw_rest_api.id
  parent_id   = aws_api_gateway_resource.this.id
  path_part   = "{proxy+}"
}


resource "aws_api_gateway_method" "any_this_proxy" {
  rest_api_id      = var.apigw_rest_api.id
  resource_id      = aws_api_gateway_resource.this_proxy.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "this_proxy" {
  rest_api_id = var.apigw_rest_api.id
  resource_id = aws_api_gateway_method.any_this_proxy.resource_id
  http_method = aws_api_gateway_method.any_this_proxy.http_method
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.this.invoke_arn

  # AWS lambdas can only be invoked with the POST method
  integration_http_method = "POST"
}


# 
# -- OPTIONS METHOD (Required for CORS)
#
resource "aws_api_gateway_method" "options" {
  rest_api_id   = var.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.this_proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = var.apigw_rest_api.id
  resource_id = aws_api_gateway_resource.this_proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = 200

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"      = true
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }

  depends_on = [aws_api_gateway_method.options]
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = var.apigw_rest_api.id
  resource_id = aws_api_gateway_resource.this_proxy.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [aws_api_gateway_method.options]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = var.apigw_rest_api.id
  resource_id = aws_api_gateway_resource.this_proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,DELETE,GET,HEAD,PATCH,POST,PUT'"
  }

  response_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [
    aws_api_gateway_method_response.options_200,
    aws_api_gateway_integration.options,
  ]
}
