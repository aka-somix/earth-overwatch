
module "bucket" {
  source = "../../modules/simple-bucket"
  bucket = "bucket-scirone-deletemeifyouseeme"
  tags   = var.tags
}
