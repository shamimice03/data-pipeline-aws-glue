# ETL Job: Transform raw events to partitioned Parquet
resource "aws_glue_job" "test_1_etl" {
  name     = "events-etl"
  role_arn = aws_iam_role.glue_crawler_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://aws-glue-assets-640168427325-ap-northeast-1/scripts/test-1.py"
    python_version  = "3"
  }

  default_arguments = {
    "--enable-metrics"               = "true"
    "--enable-spark-ui"              = "true"
    "--spark-event-logs-path"        = "s3://aws-glue-assets-640168427325-ap-northeast-1/sparkHistoryLogs/"
    "--enable-job-insights"          = "true"
    "--enable-observability-metrics" = "true"
    "--enable-glue-datacatalog"      = "true"
    "--job-bookmark-option"          = "job-bookmark-disable"
    "--job-language"                 = "python"
    "--TempDir"                      = "s3://aws-glue-assets-640168427325-ap-northeast-1/temporary/"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  max_retries = 0
  timeout     = 480

  worker_type       = "G.1X"
  number_of_workers = 10

  glue_version = "5.0"
  job_mode     = "VISUAL"
}
