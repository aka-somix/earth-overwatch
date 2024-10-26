# This is where you put your outputs declaration

output "geodb_arn" {
  value = module.geodb.cluster.arn
}

output "geodb_credentials" {
  value = module.geodb.credentials
}

output "geodb_readonlys_endpoint" {
  value = module.geodb.cluster.reader_endpoint
}

output "geo_apigw_endpoint" {
  value = aws_api_gateway_deployment.this.invoke_url
}
