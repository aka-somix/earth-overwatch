locals {
  resprefix = "${var.project_name}-${var.env}-dp-proc"
}

#
# - MAIN COMPUTE ENVIRONMENT
#
resource "aws_batch_compute_environment" "main" {
  compute_environment_name = "${local.resprefix}-main"
  type                     = "MANAGED"
  state                    = "ENABLED"

  compute_resources {
    type               = "FARGATE"
    max_vcpus          = 1024
    min_vcpus          = 0
    subnets            = var.ce_subnets_ids
    security_group_ids = var.ce_security_groups_ids
  }
}

#
# - Data Processing Queues
#

# High Priority Queue
resource "aws_batch_job_queue" "data_processing_primary" {
  name     = "${local.resprefix}-dataprocessing-primary-queue"
  priority = 1
  state    = "ENABLED"

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.main.arn
  }
}
