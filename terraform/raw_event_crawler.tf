# Catalog database
resource "aws_glue_catalog_database" "data_db" {
  name = "events_db"
}

# Glue Crawler for Raw Events
resource "aws_glue_crawler" "raw_data_crawler" {
  database_name = aws_glue_catalog_database.data_db.name
  name          = "events-raw-crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    path = "s3://${local.raw_data_bucket}/events/"
  }

  # Group all compatible schemas into a single table
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
    CreatePartitionIndex = true
  })

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }
}




