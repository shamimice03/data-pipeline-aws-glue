# Upload Glue Scripts to S3
resource "aws_s3_object" "glue_scripts" {
  for_each = fileset("${path.module}/../glue-assets/scripts", "*.py")

  bucket = local.glue_asset_bucket
  key    = "scripts/${each.value}"
  source = "${path.module}/../glue-assets/scripts/${each.value}"

  etag = filemd5("${path.module}/../glue-assets/scripts/${each.value}")
}

