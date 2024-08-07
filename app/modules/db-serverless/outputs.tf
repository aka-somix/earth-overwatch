# This is where you put your outputs declaration

output "secret_name" {
  value = aws_secretsmanager_secret.credentials.id
}

output "database_endpoint" {
  value = aws_rds_cluster.this.endpoint
}
