resource "aws_cloudwatch_event_rule" "new_img_synth" {
  name           = "${local.resprefix}-img-synth"
  event_bus_name = aws_cloudwatch_event_bus.dataplatform.name

  event_pattern = jsonencode({
    "source" : ["dataplatform"],
    "detail-type" : [{
      "wildcard" : "synthetized/*"
    }]
  })
}

resource "aws_cloudwatch_event_rule" "new_data_aerial" {
  name           = "${local.resprefix}-aerial"
  event_bus_name = aws_cloudwatch_event_bus.dataplatform.name

  event_pattern = jsonencode({
    "source" : ["dataplatform"],
    "detail-type" : [{
      "wildcard" : "aerial/*"
    }]
  })
}
