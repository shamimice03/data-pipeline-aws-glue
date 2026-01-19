# Events Processing Pipeline

## Overview

The Events Processing Pipeline is an automated AWS Glue workflow that ingests raw event data from S3, transforms it into an optimized format, and makes it available for analytics queries. The pipeline runs daily and processes nested JSON events into partitioned Parquet files.

## Architecture

### Workflow: `events-processing-pipeline`

The pipeline consists of four main components executed in sequence:

1. **Raw Data Crawler** - Discovers and catalogs raw JSON events
2. **ETL Job** - Transforms and optimizes the data
3. **Structured Data Crawler** - Catalogs the transformed output
4. **Analytics-Ready Data** - Queryable partitioned tables

## Components

### 1. Scheduled Trigger: `start-workflow`

- **Schedule**: Daily at 1 PM UTC (10 PM JST)
- **Cron Expression**: `cron(0 13 * * ? *)`
- **Action**: Initiates the raw data crawler

### 2. Crawler: `events-raw-crawler`

**Purpose**: Catalogs raw JSON event files in S3

- **Source**: `s3://cloudterms-events-data/events/`
- **Target Database**: `events_db`
- **Target Table**: `events`
- **Data Format**: JSON (nested structure)
- **Schema Policy**: CombineCompatibleSchemas
- **Trigger**: Scheduled daily

### 3. Conditional Trigger: `run-etl-after-raw-crawl`

- **Condition**: `events-raw-crawler` state = SUCCEEDED
- **Action**: Starts the ETL job

### 4. Glue Job: `events-etl`

**Purpose**: Transforms raw JSON into optimized Parquet format

- **Script Location**: `s3://cloudterms-glue-assets/scripts/events-etl.py`
- **Type**: Visual ETL
- **Glue Version**: 5.0
- **Language**: Python 3
- **Worker Configuration**: 10 x G.1X

**Processing Steps**:
1. Read data from `events_db.events` table
2. Flatten nested JSON structure
3. Add partition columns (year, month, day, hour)
4. Write as compressed Parquet files

**Output**:
- **Location**: `s3://cloudterms-events-data-outputs/`
- **Format**: Parquet with gzip compression
- **Partitioning**: `year/month/day/hour`

### 5. Conditional Trigger: `run-structured-crawler-after-etl`

- **Condition**: `events-etl` job state = SUCCEEDED
- **Action**: Starts the structured data crawler

### 6. Crawler: `structured-events-crawler`

**Purpose**: Catalogs transformed Parquet files

- **Source**: `s3://cloudterms-events-data-outputs/`
- **Target Database**: `structured_events_db`
- **Data Format**: Parquet (partitioned)
- **Crawl Policy**: CRAWL_NEW_FOLDERS_ONLY
- **Result**: Analytics-ready partitioned table

## Data Flow

```
Raw JSON Events → Flattened & Transformed → Partitioned Parquet Table
```

### Input Data
- **Location**: `s3://cloudterms-events-data/events/`
- **Format**: JSON files (`event_*.json`)
- **Structure**: Nested JSON objects

### Output Data
- **Location**: `s3://cloudterms-events-data-outputs/`
- **Format**: Parquet with gzip compression
- **Partitioning Scheme**: 
  ```
  /year=YYYY/
    /month=MM/
      /day=DD/
        /hour=HH/
  ```

## Monitoring

### Workflow Status

Monitor the workflow execution through:
- AWS Glue Console > Workflows > `events-processing-pipeline`
- CloudWatch Logs for individual job runs

### Success Criteria

The workflow completes successfully when:
1. Raw crawler successfully catalogs new events
2. ETL job transforms data without errors
3. Structured crawler updates the analytics table

### Common Issues

| Issue | Possible Cause | Resolution |
|-------|---------------|------------|
| Crawler fails | Schema incompatibility | Check JSON structure consistency |
| ETL job fails | Invalid data format | Review error logs in CloudWatch |
| Missing partitions | ETL logic error | Verify partition column generation |

## Usage

### Querying the Data

Once the pipeline completes, query the structured data using Amazon Athena:

```sql
SELECT 
    user_location,
    product_category,
    COUNT(*) as purchase_count,
    AVG(purchase_amount) as avg_amount,
    AVG(rating) as avg_rating
FROM structured_events_db.cloudterms_events_data_outputs
WHERE year = '2023' 
  AND month = '11'
  AND product_category = 'Electronics'
GROUP BY user_location, product_category
ORDER BY purchase_count DESC;
```

### Manual Execution

To manually trigger the workflow:

```bash
aws glue start-workflow-run --name events-processing-pipeline
```

### Checking Workflow Status

```bash
aws glue get-workflow-run \
  --name events-processing-pipeline \
  --run-id <run-id>
```

## Configuration

### Key Parameters

- **Schedule**: Modify the cron expression in the `start-workflow` trigger
- **Worker Count**: Adjust in the `events-etl` job configuration
- **Partitioning**: Update partition columns in the ETL script
- **Retention**: Configure S3 lifecycle policies on output bucket

## Maintenance

### Regular Tasks

- **Weekly**: Review CloudWatch logs for errors
- **Monthly**: Analyze job duration and optimize worker allocation
- **Quarterly**: Review and optimize partitioning strategy

### Schema Changes

When event schema changes:
1. Update the ETL script to handle new fields
2. Re-run the raw crawler to update the catalog
3. Test the ETL job with sample data
4. Deploy changes during off-peak hours

## Security

### IAM Roles

The workflow requires appropriate IAM roles with permissions for:
- S3 read/write access to source and destination buckets
- Glue catalog access for database and table operations
- CloudWatch Logs write access for monitoring

### Data Encryption

- **At Rest**: S3 buckets use server-side encryption
- **In Transit**: SSL/TLS encryption for all data transfers

## Cost Optimization

- Partitioning reduces query costs in Athena
- Parquet format significantly reduces storage costs
- Scheduled execution during off-peak hours
- G.1X workers balance cost and performance

## Support

For issues or questions:
- Check CloudWatch Logs for detailed error messages
- Review AWS Glue job metrics in the console
- Consult AWS Glue documentation for troubleshooting

---

**Last Updated**: January 2026  
**Pipeline Version**: 1.0  