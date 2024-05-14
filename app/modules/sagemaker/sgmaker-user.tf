resource "aws_sagemaker_user_profile" "this" {
  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = var.username

  user_settings {
    execution_role  = aws_iam_role.sagemaker_domain.arn
    security_groups = []

    canvas_app_settings {
      time_series_forecasting_settings {
        amazon_forecast_role_arn = aws_iam_role.sagemaker_forecast.arn
        status                   = "ENABLED"
      }
    }

    jupyter_server_app_settings {
      lifecycle_config_arns = []

      default_resource_spec {
        instance_type       = "system"
        sagemaker_image_arn = var.sagemaker_image_arn
      }
    }
  }

  tags = var.tags
}
