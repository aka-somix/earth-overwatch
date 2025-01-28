locals {
  resprefix = "${var.project_name}-${var.env}-landfill"
}


resource "aws_security_group" "sagemaker_outbound" {
  name = "${local.resprefix}-sagemaker-outbound"

  vpc_id = var.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all IPv4 traffic
  }

  # Allow all IPv6 outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"] # Allow all IPv6 traffic
  }
  tags = {
    "Name" = "[${local.resprefix}] VPC Egress full permissions for Sagemaker"
  }
}
