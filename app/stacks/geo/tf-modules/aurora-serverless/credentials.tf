
## secrets manager configuration

resource "aws_secretsmanager_secret" "this_credentials" {
  name = "${var.cluster_name}-credentials"

  tags = {
    "Availability" = "process-critical"
  }
}

resource "aws_secretsmanager_secret_version" "this_credentials" {
  secret_id = aws_secretsmanager_secret.this_credentials.id
  secret_string = jsonencode({
    "host" : aws_rds_cluster.this.endpoint,
    "read_host" : aws_rds_cluster.this.reader_endpoint,
    "username" : aws_rds_cluster.this.master_username,
    "password" : aws_rds_cluster.this.master_password,
    "db_engine" : "aurora-postgresql",
    "db_name" : var.database_name,
    "db_port" : 5432,
    "cluster_identifier" : aws_rds_cluster.this.cluster_identifier
  })
}
