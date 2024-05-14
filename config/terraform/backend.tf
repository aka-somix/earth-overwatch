terraform {
  backend "s3" {
    bucket         = "<%= expansion('tesi-eg-terraform-state-:ACCOUNT-:REGION') %>"
    key            = "<%= expansion(':ENV/:EXTRA/:BUILD_DIR/terraform.tfstate') %>"
    region         = "<%= expansion(':REGION') %>"
    dynamodb_table = "<%= expansion('tesi-eg-terraform-locks-:ACCOUNT-:REGION') %>"
  }
}
