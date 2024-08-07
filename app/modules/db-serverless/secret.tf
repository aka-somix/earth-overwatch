## secrets manager configuration

# secrets manager for Valorizzatore Performing db rds
resource "aws_secretsmanager_secret" "credentials" {
  name = "${var.cluster_name}-credentials-sm"
}

resource "aws_secretsmanager_secret_version" "credentials" {
  secret_id = aws_secretsmanager_secret.credentials.id
  secret_string = jsonencode({
    "host" : aws_rds_cluster.this.endpoint,
    "read_host" : aws_rds_cluster.this.reader_endpoint,
    "username" : aws_rds_cluster.this.master_username,
    "password" : aws_rds_cluster.this.master_password,
    "db_engine" : var.rds_aurora_properties.db_type,
    "db_name" : var.rds_aurora_properties.db_name,
    "db_port" : var.rds_aurora_properties.db_port,
    "cluster_identifier" : aws_rds_cluster.this.cluster_identifier
  })
}
