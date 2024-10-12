## Aurora Database configuration
resource "aws_rds_cluster" "this" {
  cluster_identifier = var.cluster_name

  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = var.engine_version
  database_name           = var.database_name
  master_username         = var.username
  master_password         = var.password
  preferred_backup_window = "07:00-09:00"
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  db_subnet_group_name = aws_db_subnet_group.this_rds.name

  vpc_security_group_ids = var.database_security_groups_ids

  serverlessv2_scaling_configuration {
    max_capacity = 4
    min_capacity = 0.5
  }

  tags = var.tags
}

resource "aws_rds_cluster_instance" "this_instance_readwrite" {
  identifier = "${var.cluster_name}-instance-rw-01"

  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless"
  engine             = "aurora-postgresql"
  engine_version     = 15.4

  tags = var.tags
}

resource "aws_db_subnet_group" "this_rds" {
  name       = "${var.cluster_name}-rds-sub-group"
  subnet_ids = var.database_subnets_ids
}
