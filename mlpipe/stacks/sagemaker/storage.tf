resource "aws_efs_file_system" "dataset_storage" {
  creation_token = "${local.resprefix}-dataset-storage"

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
}

resource "aws_efs_mount_target" "dataset_storage" {
  file_system_id = aws_efs_file_system.dataset_storage.id
  subnet_id      = data.aws_subnets.rfalabs_dmz.ids[0]
}
