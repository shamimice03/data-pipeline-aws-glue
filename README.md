┌─────────────────────────────────────────────────────────────────┐
│                    AWS GLUE WORKFLOW                             │
│              events-processing-pipeline                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ SCHEDULED
                              │ cron(0 13 * * ? *)
                              │ (1 PM UTC / 10 PM JST daily)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TRIGGER: start-workflow (SCHEDULED)                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Action: Start Crawler                                   │  │
│  │   events-raw-crawler                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Start Crawler
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CRAWLER: events-raw-crawler                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Source: s3://cloudterms-events-data/events/            │  │
│  │ Target: events_db.events table                          │  │
│  │ Format: JSON (nested structure)                         │  │
│  │ Policy: CombineCompatibleSchemas                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ State: SUCCEEDED
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TRIGGER: run-etl-after-raw-crawl (CONDITIONAL)                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Condition: events-raw-crawler = SUCCEEDED                │  │
│  │ Action: Start Job                                       │  │
│  │   events-etl                                            │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Start Job
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  GLUE JOB: events-etl                                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Script: s3://cloudterms-glue-assets/scripts/events-etl.py│  │
│  │ Type: VISUAL ETL (Glue 5.0, Python 3)                   │  │
│  │ Workers: 10 x G.1X                                       │  │
│  │                                                            │  │
│  │ Process:                                                  │  │
│  │ 1. Read from events_db.events                            │  │
│  │ 2. Flatten nested JSON structure                         │  │
│  │ 3. Add partition columns (year, month, day, hour)        │  │
│  │ 4. Write as partitioned Parquet                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                     │
│                          ▼                                     │
│         ┌────────────────────────────────┐                     │
│         │  OUTPUT: S3                   │                     │
│         │  s3://cloudterms-events-data-outputs               │
│         │  Format: Parquet (gzip)       │                     │
│         │  Partitioned by:              │                     │
│         │  year/month/day/hour          │                     │
│         └────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ State: SUCCEEDED
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  TRIGGER: run-structured-crawler-after-etl (CONDITIONAL)        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Condition: events-etl job = SUCCEEDED                    │  │
│  │ Action: Start Crawler                                   │  │
│  │   structured-events-crawler                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Start Crawler
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CRAWLER: structured-events-crawler                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Source: s3://cloudterms-events-data-outputs             │  │
│  │ Target: structured_events_db table                       │  │
│  │ Format: Parquet (partitioned)                           │  │
│  │ Policy: CRAWL_NEW_FOLDERS_ONLY                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   COMPLETED     │
                    │  Ready for      │
                    │   Analytics     │
                    └─────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                        DATA FLOW                                 │
└─────────────────────────────────────────────────────────────────┘

Raw JSON Events              Transformed               Optimized
[Nested Structure]    →    Parquet Files      →    Partitioned Table

s3://cloudterms-           s3://cloudterms-        structured_events_db
events-data/                events-data-outputs
 /events/                    /year=2024/
  event_*.json               /month=01/
                             /day=15/
                             /hour=14/
