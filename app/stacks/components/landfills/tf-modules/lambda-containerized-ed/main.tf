locals {
    image_tag = uuid()
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name

  package_type  = "Image"
  image_uri = "${var.ecr_repository_url}:${local.image_tag}"

  memory_size   = var.memory_size
  timeout       = var.timeout

  role = aws_iam_role.this.arn

  dynamic "vpc_config" {
    for_each = var.vpc.enabled ? [1] : []
    content {
      subnet_ids         = var.vpc.subnet_ids
      security_group_ids = var.vpc.security_group_ids
    }
  }

  environment {
    variables = var.env_vars
  }

  depends_on = [ null_resource.build_and_upload_image ]
}

#
# IAM Role for Lambda function
#
resource "aws_iam_role" "this" {
  name = "${var.function_name}-lambdarole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
}

# Lambda Basics Policy (Cloudwatch logs)
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda VPC Access
resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}



#
# -------------- Lambda container build and upload --------------
#
resource "null_resource" "build_and_upload_image" {
  # Specify triggers if needed, such as files or other resources the script depends on
  triggers = {
    timestamp = "${timestamp()}"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_code_folder}"
    command     = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_registry}"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_code_folder}"
    command     = "docker build -t ${var.function_name} . --platform=linux/x86_64"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_code_folder}"
    command     = "docker tag ${var.function_name}:latest ${var.ecr_repository_url}:${local.image_tag}"
  }

  provisioner "local-exec" {
    working_dir = "${var.source_code_folder}"
    command     = "docker push ${var.ecr_repository_url}:${local.image_tag}"
  }
}


# -------------- Cloudwatch Log Group --------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.logs_retention_days
}

# -------------- RESOURCE POLICY --------------
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"

  # Replace with your custom event bus ARN
  source_arn = var.eventbridge_bus_arn
}
