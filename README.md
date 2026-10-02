# NYC Taxi Data Pipeline

A batch ELT pipeline that ingests NYC TLC taxi trip data, cleans and transforms it with AWS Glue, loads it into a Redshift star schema, and orchestrates the whole flow with Step Functions — with monitoring via CloudWatch and SNS.

Built as a hands-on project while studying for the AWS Certified Data Engineer - Associate (DEA-C01) exam.

## Problem

Raw taxi trip data (3.8M+ rows/month) needs to go from a single messy source file to a queryable, analytics-ready warehouse — with the kind of data quality issues real pipelines actually hit: nullable fields, dead columns, and corrupted timestamps (the source file contained trips dated as far back as 2008 despite being a "June 2026" extract).

## Architecture

```
NYC TLC Open Data (Parquet)
        |
        v
  S3 raw-zone  ──────────────┐
        |                    │
        v                    │
  Glue Crawler                │  <- catalogs raw schema (metadata only)
        |                    │
        v                    │
  Glue ETL Job (PySpark)      │  <- cleans, filters, partitions by date
        |                    │
        v                    │
  S3 processed-zone           │  (partitioned: year/month/day)
        |                    │
        v                    │
  Glue Crawler (processed)    │  <- catalogs cleaned schema
        |                    │
        v                    │
  Redshift Serverless         │
   - fact_trips               │
   - dim_date / dim_location / dim_vendor
        |
        v
  Analytical SQL queries

Orchestration: AWS Step Functions wires the crawler -> Glue job -> crawler
chain together, with error handling (Catch) routing failures to a Fail
state. CloudWatch alarm on ExecutionsFailed -> SNS -> email notification.
```

**Why this stack:**
- **S3 two-zone split** (raw/processed) — raw data stays untouched as a rebuild source; processed data is partitioned for query efficiency.
- **Glue (managed Spark)** over a plain script — scales past single-machine memory, serverless, no cluster management. Chosen over EMR for this use case since Glue's job/crawler model fits a straightforward batch ETL better than manually managing a cluster.
- **Redshift over querying S3 directly (Athena)** — this is a warehouse built for sustained, repeated analytical queries (joins across dimension tables, aggregations), not ad-hoc one-off lookups.
- **Star schema** — `fact_trips` holds measurable values; `dim_date`/`dim_location`/`dim_vendor` hold descriptive context. Avoids repeating text across millions of rows and makes aggregation queries a simple join + group-by.
- **Step Functions over manual triggering** — the pipeline needs to run as one coordinated flow with error handling, not three separately-clicked console actions.

## Data quality handling

- Dropped a column (`request_source`) that was entirely null in the source file.
- Dropped rows missing critical fields (`passenger_count`, `RatecodeID`).
- Cast `store_and_fwd_flag` from a Y/N string to boolean.
- **Filtered out-of-range timestamps** — the raw file contained trips dated outside June 2026, including one from 2008. Added an explicit date-range filter (`WHERE pickup_datetime BETWEEN '2026-06-01' AND '2026-07-01'`) rather than trusting the file's advertised date range.

## Schema design

`fact_trips` is distributed and sorted on `pickup_date_id` (`DISTKEY`/`SORTKEY`), since nearly every analytical query filters or groups by date — this keeps related rows physically together and reduces the data scanned per query.

## Debugging notes (the real work)

A pipeline that works on the first try usually means something's untested. These are the actual issues hit and fixed during the build:

- **IAM scoping, repeatedly.** Separate roles for Glue (raw-zone read vs. processed-zone write), Redshift's `COPY` role, and the Step Functions execution role each needed explicit, narrowly-scoped permissions — no single role "just worked" by default. Hit this independently for S3 writes, S3 reads, Glue crawler/job execution, and CloudWatch log delivery.
- **Redshift COPY matches Parquet columns by name, not position.** A staging table built via `LIKE` carried over different column names than the source file (`pickup_location_id` vs. the file's `PULocationID`), causing silent NULL mapping and a `NOT NULL` constraint failure traced back to a column (`trip_id`) that a failed `ALTER TABLE DROP COLUMN` had left behind. Fixed by rebuilding the staging table with column names matching the file exactly.
- **Type mismatches in Spectrum scans.** Spark wrote `passenger_count`/`ratecodeid`/`payment_type` as `bigint`, not the `smallint` originally assumed — Redshift doesn't silently narrow types, so the staging table had to match exactly.
- **Stale Glue Catalog partitions.** After fixing the timestamp filter and re-running the ETL job, the catalog kept listing partitions (`year=2008`, etc.) for S3 paths that no longer existed — the crawler doesn't auto-remove stale partitions by default. Fixed by deleting and recrawling.
- **Visual Step Functions designer left placeholder values.** Both `Glue: StartCrawler` states initially pointed at a nonexistent crawler named `MyData` — a template default that never got replaced. The resulting `AccessDeniedException` initially looked like an IAM problem; the real issue was a wrong resource name, not a missing permission.
- **CloudWatch alarm statistic.** `ExecutionsFailed` is a count-type metric; alarms on count metrics should use `Sum`, not `Average`, to reliably catch isolated events.

## Stack

- **Ingestion:** S3
- **Transformation:** AWS Glue (PySpark)
- **Warehouse:** Amazon Redshift Serverless
- **Orchestration:** AWS Step Functions
- **Monitoring:** CloudWatch Alarms + SNS

## Repo structure

```
glue-scripts/
  cleaning.py              -- Glue ETL job: clean, filter, partition
redshift/
  create_tables.sql        -- star schema DDL
  load_dimensions.sql      -- dim_date / dim_location / dim_vendor loads
  load_fact_trips.sql      -- staging + fact_trips load
  analytical_queries.sql   -- sample analytical queries
step-functions/
  state_machine.json       -- orchestration definition
```
