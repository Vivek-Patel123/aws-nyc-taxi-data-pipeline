-- Staging table matches the Parquet file's actual column names and types exactly,
-- since Redshift's Parquet COPY matches columns by name, not position.
DROP TABLE IF EXISTS staging_trips;

CREATE TABLE staging_trips (
    vendorid                INT,
    tpep_pickup_datetime    TIMESTAMP,
    tpep_dropoff_datetime   TIMESTAMP,
    passenger_count         BIGINT,
    trip_distance           DOUBLE PRECISION,
    ratecodeid              BIGINT,
    store_and_fwd_flag      BOOLEAN,
    pulocationid            INT,
    dolocationid            INT,
    payment_type            BIGINT,
    fare_amount              DOUBLE PRECISION,
    extra                    DOUBLE PRECISION,
    mta_tax                  DOUBLE PRECISION,
    tip_amount                DOUBLE PRECISION,
    tolls_amount              DOUBLE PRECISION,
    improvement_surcharge     DOUBLE PRECISION,
    total_amount               DOUBLE PRECISION,
    congestion_surcharge       DOUBLE PRECISION,
    airport_fee                 DOUBLE PRECISION,
    cbd_congestion_fee           DOUBLE PRECISION
);

COPY staging_trips
FROM 's3://processed-zone-889387846031-us-east-2-an/yellow_tripdata/'
IAM_ROLE default
FORMAT AS PARQUET
REGION 'us-east-2';

INSERT INTO fact_trips
SELECT
    ROW_NUMBER() OVER () AS trip_id,
    vendorid AS vendor_id,
    CAST(TO_CHAR(tpep_pickup_datetime, 'YYYYMMDD') AS INT) AS pickup_date_id,
    pulocationid AS pickup_location_id,
    dolocationid AS dropoff_location_id,
    tpep_pickup_datetime AS pickup_datetime,
    tpep_dropoff_datetime AS dropoff_datetime,
    passenger_count,
    trip_distance,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    payment_type,
    store_and_fwd_flag
FROM staging_trips;

DROP TABLE staging_trips;