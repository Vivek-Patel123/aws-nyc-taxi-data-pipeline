import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, when, year, month, dayofmonth

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

raw_path = "s3://raw-zone-889387846031-us-east-2-an/yellow_tripdata_2026-06.parquet"
processed_path = "s3://processed-zone-889387846031-us-east-2-an/yellow_tripdata/"

# Read raw data
df = spark.read.parquet(raw_path)

# Drop the column that was empty in the sample
df = df.drop("request_source")

# Drop rows missing critical fields
df = df.na.drop(subset=["passenger_count", "RatecodeID"])

# Convert Y/N string to boolean
df = df.withColumn(
    "store_and_fwd_flag",
    when(col("store_and_fwd_flag") == "Y", True).otherwise(False)
)

# Keep only trips picked up in June 2026 (raw file contains out-of-range timestamps,
# including a trip dated 2008)
df = df.filter(
    (col("tpep_pickup_datetime") >= "2026-06-01") &
    (col("tpep_pickup_datetime") < "2026-07-01")
)

# Derive partition columns from the pickup timestamp
df = df.withColumn("year", year(col("tpep_pickup_datetime")))
df = df.withColumn("month", month(col("tpep_pickup_datetime")))
df = df.withColumn("day", dayofmonth(col("tpep_pickup_datetime")))

# Group rows by date before writing so each day's folder gets one file
# instead of many small fragments
df = df.repartition("year", "month", "day")

# Write Parquet partitioned by date
df.write.partitionBy("year", "month", "day").mode("overwrite").parquet(processed_path)

job.commit()