env  = "<%= Terraspace.env %>"
region = "eu-west-1"
project = "sctesi"

default_tags = {
    "Owner" = "s.cirone"
    "Project" = "sctesi"
    "Repository" = "scirone-tesi-infra"
    "Iac" = "Terraspace"
    "CreatedAt" = "${formatdate("YYYY-MM-DD", timestamp())}"
}
