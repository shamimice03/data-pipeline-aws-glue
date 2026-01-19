import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsgluedq.transforms import EvaluateDataQuality
from awsglue import DynamicFrame


def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Default ruleset used by all target nodes with data quality enabled
DEFAULT_DATA_QUALITY_RULESET = """
    Rules = [
        ColumnCount > 0
    ]
"""

# Script generated for node AWS Glue Data Catalog
AWSGlueDataCatalog_node1768740156292 = glueContext.create_dynamic_frame.from_catalog(
    database="test",
    table_name="events",
    transformation_ctx="AWSGlueDataCatalog_node1768740156292",
)

# Script generated for node SQL Query
SqlQuery1 = """
SELECT 
  event_id,
  COALESCE(user.id, user_id) as user_id,
  COALESCE(user.age, user_age) as user_age,
  COALESCE(user.location, location) as location,
  COALESCE(product_details.product_id, product_id) as product_id,
  COALESCE(product_details.category, product_category) as product_category,
  COALESCE(transaction.amount, purchase_amount) as purchase_amount,
  COALESCE(transaction.currency, currency) as currency,
  COALESCE(transaction.timestamp, timestamp) as timestamp,
  COALESCE(feedback.rating, review.rating) as rating,
  COALESCE(feedback.review_text, review.review_text) as review_text
FROM myDataSource
"""
SQLQuery_node1768740177246 = sparkSqlQuery(
    glueContext,
    query=SqlQuery1,
    mapping={"myDataSource": AWSGlueDataCatalog_node1768740156292},
    transformation_ctx="SQLQuery_node1768740177246",
)

# Script generated for node Change Schema
ChangeSchema_node1768740734843 = ApplyMapping.apply(
    frame=SQLQuery_node1768740177246,
    mappings=[
        ("event_id", "string", "event_id", "string"),
        ("user_id", "string", "user_id", "string"),
        ("user_age", "int", "user_age", "int"),
        ("location", "string", "user_location", "string"),
        ("product_id", "string", "product_id", "string"),
        ("product_category", "string", "product_category", "string"),
        ("purchase_amount", "double", "purchase_amount", "double"),
        ("currency", "string", "currency", "string"),
        ("timestamp", "string", "timestamp", "timestamp"),
        ("rating", "int", "rating", "double"),
        ("review_text", "string", "review_text", "string"),
    ],
    transformation_ctx="ChangeSchema_node1768740734843",
)

# Script generated for node SQL Query
SqlQuery0 = """
SELECT
    *,
    year(timestamp) AS year,
    month(timestamp) AS month,
    dayofmonth(timestamp) AS day,
    hour(timestamp) AS hour
FROM myDataSource
"""
SQLQuery_node1768740795144 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={"myDataSource": ChangeSchema_node1768740734843},
    transformation_ctx="SQLQuery_node1768740795144",
)

# Script generated for node Amazon S3
EvaluateDataQuality().process_rows(
    frame=SQLQuery_node1768740795144,
    ruleset=DEFAULT_DATA_QUALITY_RULESET,
    publishing_options={
        "dataQualityEvaluationContext": "EvaluateDataQuality_node1768740683804",
        "enableDataQualityResultsPublishing": True,
    },
    additional_options={
        "dataQualityResultsPublishing.strategy": "BEST_EFFORT",
        "observations.scope": "ALL",
    },
)
AmazonS3_node1768741302064 = glueContext.write_dynamic_frame.from_options(
    frame=SQLQuery_node1768740795144,
    connection_type="s3",
    format="glueparquet",
    connection_options={
        "path": "s3://cloudterms-events-data-outputs",
        "partitionKeys": ["year", "month", "day", "hour"],
    },
    format_options={"compression": "gzip"},
    transformation_ctx="AmazonS3_node1768741302064",
)

job.commit()
