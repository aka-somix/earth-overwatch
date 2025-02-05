
#
# ------------------------------------------- DATABASE -------------------------------------------
#
resource "aws_glue_catalog_database" "aerial" {
  name = "aerial"
  description = "Aerial data. Created by ${local.resprefix} stack"
}

resource "aws_iam_policy" "aerial_db_access" {
  name = "${local.resprefix}-aerial-db-full-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "glue:Get*",
          "glue:BatchGet*",
          "glue:BatchCreate*",
          "glue:Create*",
          "glue:Update*",
          "glue:BatchUpdate*",
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:glue:${var.region}:${var.account_id}:catalog",
          "arn:aws:glue:${var.region}:${var.account_id}:database/${aws_glue_catalog_database.aerial.name}",
          "arn:aws:glue:${var.region}:${var.account_id}:table/${aws_glue_catalog_database.aerial.name}/*",
          "arn:aws:glue:${var.region}:${var.account_id}:partition/${aws_glue_catalog_database.aerial.name}/*/*",
        ]
      }
  ] })
}

#
# ------------------------------------------- TABLES -------------------------------------------
#
resource "aws_glue_catalog_table" "aerial_tables" {
  count = length(var.aerial_db_tables)

  name          = var.aerial_db_tables[count.index].name
  database_name = aws_glue_catalog_database.aerial.name

  # TABLE PARAMETERS
  parameters = {
    classification      = "parquet"
    "parquet.compression" = "SNAPPY"
  }

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${module.refined_data_zone_bucket.name}/${var.aerial_db_tables[count.index].path}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = 1
      }
    }

    dynamic "columns" {
      for_each = var.aerial_db_tables[count.index].columns
      content {
        name = columns.value["Name"]
        type = columns.value["Type"]
      }
    }
  }

  dynamic "partition_keys" {
    for_each = var.aerial_db_tables[count.index].partitions
    content {
      name = partition_keys.value["Name"]
      type = partition_keys.value["Type"]
    }
  }
}
