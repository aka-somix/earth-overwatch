# This is where you put your outputs declaration

output "dataplatform_eventbus" {
  value = aws_cloudwatch_event_bus.dataplatform
}

output "backend_eventbus" {
  value = aws_cloudwatch_event_bus.backend
}

#
# ------------------------------ DATA PLATFORM ------------------------------
#
output "eventrule_new_image_data_from_synth" {
  value = aws_cloudwatch_event_rule.new_img_synth
}

#
# ------------------------------ BACKEND -----------------------------------
#

output "eventrule_be_detect_landfills" {
  value = aws_cloudwatch_event_rule.detect_landfills
}
