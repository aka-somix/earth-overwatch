resource "aws_efs_file_system" "dataset_storage" {
  creation_token = "${local.resprefix}-dataset-storage"

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }

  tags = {
    "Name" = "${local.resprefix}-dataset-storage"
  }
}

resource "aws_efs_mount_target" "dataset_storage_a" {
  file_system_id  = aws_efs_file_system.dataset_storage.id
  subnet_id       = data.aws_subnets.rfalabs_dmz.ids[0]
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "dataset_storage_b" {
  file_system_id  = aws_efs_file_system.dataset_storage.id
  subnet_id       = data.aws_subnets.rfalabs_dmz.ids[1]
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "dataset_storage_c" {
  file_system_id  = aws_efs_file_system.dataset_storage.id
  subnet_id       = data.aws_subnets.rfalabs_dmz.ids[2]
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_access_point" "dataset_storage" {
  file_system_id = aws_efs_file_system.dataset_storage.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/datasets"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

# Security Group for EFS
resource "aws_security_group" "efs_sg" {
  name        = "${local.resprefix}-efs-sg"
  description = "Allow inbound NFS traffic from Lambda"
  vpc_id      = data.aws_vpc.rfa_labs.id

  ingress {
    description = "NFS from Lambda"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.rfa_labs.cidr_block]
  }
}
