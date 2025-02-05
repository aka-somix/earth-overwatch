resource "aws_glue_job" "refine_oam" {
  name        = "${local.resprefix}-refine-oam"
  description = "Processing job for refining data from Open Aerial Map (oam)"

  role_arn = aws_iam_role.processing_glue_jobs.arn

  worker_type       = "G.1X"
  number_of_workers = 2
  glue_version      = "4.0"
  timeout           = 120 # 2 hours

  command {
    script_location = "s3://${aws_s3_object.glue_script_upload.bucket}/${aws_s3_object.glue_script_upload.key}"
    python_version  = 3
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.refine_oam.name
    "--enable-glue-datacatalog"          = "true"
    "--enable-glue-datacatalog"          = "true"
    # Apache Sedona
    "--additional-python-modules"        = "apache-sedona==1.7.0"
    "--extra-jars"                       = "https://repo1.maven.org/maven2/org/apache/sedona/sedona-spark-shaded-3.3_2.12/1.7.0/sedona-spark-shaded-3.3_2.12-1.7.0.jar,https://repo1.maven.org/maven2/org/datasyslab/geotools-wrapper/1.7.0-28.5/geotools-wrapper-1.7.0-28.5.jar"
    # Runtime parameters
    "--source_json_s3_path"              = "s3://${var.landing_zone_bucket.name}/oam/metadata/italy/2024/04/08/1738591402.json"
    "--destination_s3_path"              = "s3://${var.refined_zone_bucket.name}/oam/metadata/region=italy"
    "--destination_table"                = "aerial.oam"
  }
}

# ------------ UPLOAD SCRIPT TO S3 ------------
resource "aws_s3_object" "glue_script_upload" {
  key    = "${var.project_name}/processing/oam_refine.py"
  bucket = var.aws_s3_bucket_glue_packages_name
  source = "${path.module}/glue-jobs/src/oam_refine.py"
  etag   = filemd5("${path.module}/glue-jobs/src/oam_refine.py")
}

# -------------- Cloudwatch Log Group --------------

resource "aws_cloudwatch_log_group" "refine_oam" {
  name              = "/${var.project_name}/glue/processing/refine-oam"
  retention_in_days = 7
}
