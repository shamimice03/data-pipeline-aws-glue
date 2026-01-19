# Catalog database
resource "aws_glue_catalog_database" "structured_data_db" {
  name = "structured_events_db"
}

# Glue Crawler
resource "aws_glue_crawler" "structured_data_crawler" {
  database_name = aws_glue_catalog_database.structured_data_db.name
  name          = "structured-events-crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    path = "s3://cloudterms-events-data-outputs"
  }

  # Crawl partitioned Parquet data
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
