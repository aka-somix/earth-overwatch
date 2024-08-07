# This is where you put your resource declaration
## Aurora Database configuration

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = var.cluster_name

  engine                  = "aurora-postgresql"
  engine_mode             = "serverless"
  engine_version          = "15.4"
  database_name           = var.database_name
  master_username         = "admin"
  master_password         = random_password.password.result
  preferred_backup_window = "05:00-07:00"
  backup_retention_period = 1
  skip_final_snapshot     = false
  deletion_protection     = var.deletion_protection

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [
    aws_security_group.this_rds.id
  ]

  serverlessv2_scaling_configuration {
    max_capacity = var.max_capacity
    min_capacity = var.min_capacity
  }

  # Parameter Group
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

}

resource "aws_rds_cluster_instance" "this_rw" {
  identifier = "${var.cluster_name}-rw-instance"

  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.rds_aurora_properties.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
}

resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${var.cluster_name}-parameters"
  family      = var.rds_aurora_properties.cluster_parameter_group_family
  description = "RDS Cluster Parameter Group for ${var.cluster_name} database"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.cluster_name}-subnets-group"
  subnet_ids = var.subnet_ids
}
