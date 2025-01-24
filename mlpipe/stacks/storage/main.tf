locals {
  resprefix = "${var.project_name}-${var.env}-storage"
}

data "aws_efs_file_system" "datasets" {
  tags = {
    Name = var.datasets_efs_tagname
  }
}