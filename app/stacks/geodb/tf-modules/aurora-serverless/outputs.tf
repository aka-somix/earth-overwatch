# This is where you put your outputs declaration

output "cluster" {
  value = aws_rds_cluster.this
}

output "credentials" {
  value = aws_secretsmanager_secret.this_credentials
}
