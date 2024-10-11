locals {
  resprefix = "${var.project_name}-${var.env}-events"
}

# This is where you put your resource declaration
resource "aws_cloudwatch_event_bus" "dataplatform" {
  name = "${local.resprefix}-dataplatform-broker"
}

resource "aws_cloudwatch_event_bus" "bff" {
  name = "${local.resprefix}-bff-broker"
}
