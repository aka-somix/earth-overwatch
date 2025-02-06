locals {
  resprefix = "${var.project_name}-${var.env}-ingest-oam"
}

resource "aws_sns_topic" "new_data_uploaded" {
  name = "${local.resprefix}-new-data-uploaded-topic"
}
