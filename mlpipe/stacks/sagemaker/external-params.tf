# Dinamically Retrieve landingzone bucket name
data "aws_ssm_parameter" "landingzonebucket" {
  name = "/${var.env}/${var.project_name}/dataplat/landingzonebucket"
}

# Dinamically Retrieve aimodels bucket name
data "aws_ssm_parameter" "aimodelsbucket" {
  name = "/${var.env}/${var.project_name}/dataplat/aimodelsbucket"
}
