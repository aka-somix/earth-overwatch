# This is where you put your outputs declaration

output "dataplatform_eventbus" {
  value = aws_cloudwatch_event_bus.dataplatform
}

output "eventrule_new_image_data_from_synth" {
  value = aws_cloudwatch_event_rule.new_img_synth
}