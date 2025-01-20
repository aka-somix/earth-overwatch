# This is where you put your outputs declaration

#
# - LANDING ZONE
#

output "landing_zone_bucket" {
  value = module.landing_zone_bucket
}
output "aws_policy_landingzonebucket_readonly" {
  value = aws_iam_policy.landingzonebucket_readonly
}
output "aws_policy_landingzonebucket_writeread" {
  value = aws_iam_policy.landingzonebucket_writeread
}
output "aws_policy_landingzonebucket_full" {
  value = aws_iam_policy.landingzonebucket_full
}

#
# - REFINED DATA ZONE
#
output "refined_zone_bucket" {
  value = module.refined_data_zone_bucket
}
output "aws_policy_redefinedzone_readonly" {
  value = aws_iam_policy.refineddatazone_readonly
}
output "aws_policy_redefinedzone_writeread" {
  value = aws_iam_policy.refineddatazone_writeread
}
output "aws_policy_redefinedzone_full" {
  value = aws_iam_policy.landingzonebucket_full
}

#
# - AI MODELS
#
output "aws_policy_aimodelsbucket_readonly" {
  value = aws_iam_policy.aimodelsbucket_readonly
}
output "aws_policy_aimodelsbucket_writeread" {
  value = aws_iam_policy.aimodelsbucket_writeread
}
