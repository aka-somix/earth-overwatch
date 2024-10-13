# This is where you put your resource declaration
locals {
  resprefix = "${var.project_name}-${var.env}-bastion"
}

resource "aws_launch_template" "this" {
  name                    = "${local.resprefix}-host"
  image_id                = "ami-04e49d62cf88738f1"
  instance_type           = "t3.micro"
  user_data               = filebase64("${path.module}/userdata/userdata.sh")
  key_name                = var.ssh_key_pair_name
  disable_api_termination = true

  network_interfaces {
    subnet_id                   = var.subnet_id
    associate_public_ip_address = false
    security_groups             = var.security_group_ids
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    no_device   = true
    ebs {
      volume_size           = 16
      encrypted             = false
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        "Name" = "${local.resprefix}-bastionhost"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        "Name" = "${local.resprefix}-bastionhost"
      }
    )
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "this" {
  name = "${local.resprefix}-ag"

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
  }

  desired_capacity = var.desired_capacity
  max_size         = var.max_capacity
  min_size         = var.min_capacity

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- IAM ROLES AND POLICIES ----------
resource "aws_iam_instance_profile" "this" {
  name = "${local.resprefix}-instance-profile"
  role = aws_iam_role.this.id
}

resource "aws_iam_role" "this" {
  name = "${local.resprefix}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "ssm"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
            "ssm:UpdateInstanceInformation",
            "ssm-guiconnect:CancelConnection",
            "ssm-guiconnect:GetConnection",
            "ssm-guiconnect:StartConnection"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:GetEncryptionConfiguration"
          ],
          "Resource" : [
            "arn:aws:s3:::mps-*-session-manager-logs",
            "arn:aws:s3:::mps-*-session-manager-logs/*"
          ],
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "s3:GetEncryptionConfiguration"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "kms:GenerateDataKey"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        }
      ]
    })
  }

  inline_policy {
    name = "system-access"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:GetObject"
          ],
          "Resource" : [
            "arn:aws:s3:::aws-ssm-*/*",
            "arn:aws:s3:::aws-windows-downloads-*/*",
            "arn:aws:s3:::amazon-ssm-*/*",
            "arn:aws:s3:::amazon-ssm-packages-*/*",
            "arn:aws:s3:::*-birdwatcher-prod/*",
            "arn:aws:s3:::aws-ssm-distributor-file-*/*",
            "arn:aws:s3:::aws-ssm-document-attachments-*/*",
            "arn:aws:s3:::patch-baseline-snapshot-*/*"
          ],
          "Effect" : "Allow"
        }
      ]
    })
  }

  inline_policy {
    name = "opensearch-access"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "es:*"
          ],
          "Resource" : "arn:aws:es:*:*:domain/*"
        }
      ]
    })
  }

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
