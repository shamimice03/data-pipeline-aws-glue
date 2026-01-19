# -----------------------------------------------------------------------------
# WORKFLOW: Raw Crawler → ETL Job → Structured Events Crawler
# -----------------------------------------------------------------------------

# Glue Workflow to orchestrate the complete pipeline
resource "aws_glue_workflow" "etl_pipeline" {
  name = "events-processing-pipeline"
}

# Trigger 0: Start the workflow on schedule (10 PM JST / 1 PM UTC daily)
resource "aws_glue_trigger" "start_workflow" {
  name          = "start-workflow"
  workflow_name = aws_glue_workflow.etl_pipeline.name
  type          = "SCHEDULED"
  schedule      = "cron(0 13 * * ? *)" # 1 PM UTC is 10 PM JST (UTC+9)

  actions {
    crawler_name = "events-raw-crawler"
  }
}

# Trigger 1: Start ETL job when raw crawler succeeds
resource "aws_glue_trigger" "run_etl_after_raw_crawl" {
  name          = "run-etl-after-raw-crawl"
  workflow_name = aws_glue_workflow.etl_pipeline.name
  type          = "CONDITIONAL"

  predicate {
    conditions {
      crawler_name = "events-raw-crawler"
      crawl_state  = "SUCCEEDED"
    }
    logical = "AND"
  }

  actions {
    job_name = aws_glue_job.test_1_etl.name
  }
}

# Trigger 2: Run structured events crawler after ETL job succeeds
resource "aws_glue_trigger" "run_structured_crawler_after_etl" {
  name          = "run-structured-crawler-after-etl"
  workflow_name = aws_glue_workflow.etl_pipeline.name
  type          = "CONDITIONAL"

  predicate {
    conditions {
      job_name = aws_glue_job.test_1_etl.name
      state    = "SUCCEEDED"
    }
    logical = "AND"
  }

  actions {
    crawler_name = "structured-events-crawler"
  }
}

