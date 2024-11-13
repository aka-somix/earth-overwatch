resource "aws_cloudwatch_event_rule" "detect_landfills" {
  name           = "${local.resprefix}-detect-landfills"
  event_bus_name = aws_cloudwatch_event_bus.backend.name

  event_pattern = jsonencode({
    "detail-type" : ["detect/landfills"]
  })
}
