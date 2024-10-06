# This is where you put your resource declaration
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = var.api_description
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Create a resource in the API Gateway
resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "/"
}

#
# --- Health resource ---
#
resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "health"
}

resource "aws_api_gateway_method" "get_health" {
  http_method      = "GET"
  resource_id      = aws_api_gateway_resource.health.id
  rest_api_id      = aws_api_gateway_rest_api.this.id
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "health" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.get_health.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_method_response" "health_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.get_health.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    aws_api_gateway_model.empty,
    aws_api_gateway_integration.health
  ]
}

resource "aws_api_gateway_model" "empty" {
  rest_api_id  = aws_api_gateway_rest_api.this.id
  name         = "Empty"
  description  = "an Empty JSON schema"
  content_type = "application/json"

  schema = <<EOF
{
  "type": "object"
}
EOF
}

resource "aws_api_gateway_integration_response" "health_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.get_health.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.health
  ]
}
