CREATE TABLE dim_date (
    date_id       INT PRIMARY KEY,
    full_date     DATE,
    year          SMALLINT,
    month         SMALLINT,
    day           SMALLINT,
    day_of_week   VARCHAR(10),
    is_weekend    BOOLEAN
);

CREATE TABLE dim_location (
    location_id   INT PRIMARY KEY,
    borough       VARCHAR(50),
    zone_name     VARCHAR(100),
    service_zone  VARCHAR(50)
);

CREATE TABLE dim_vendor (
    vendor_id     INT PRIMARY KEY,
    vendor_name   VARCHAR(50)
);

CREATE TABLE fact_trips (
    trip_id                BIGINT PRIMARY KEY,
    vendor_id               INT REFERENCES dim_vendor(vendor_id),
    pickup_date_id           INT REFERENCES dim_date(date_id),
    pickup_location_id       INT REFERENCES dim_location(location_id),
    dropoff_location_id      INT REFERENCES dim_location(location_id),
    pickup_datetime          TIMESTAMP,
    dropoff_datetime         TIMESTAMP,
    passenger_count          SMALLINT,
    trip_distance            DECIMAL(8,2),
    fare_amount              DECIMAL(8,2),
    extra                    DECIMAL(8,2),
    mta_tax                  DECIMAL(8,2),
    tip_amount                DECIMAL(8,2),
    tolls_amount              DECIMAL(8,2),
    improvement_surcharge     DECIMAL(8,2),
    total_amount               DECIMAL(8,2),
    congestion_surcharge       DECIMAL(8,2),
    airport_fee                DECIMAL(8,2),
    payment_type                SMALLINT,
    store_and_fwd_flag           BOOLEAN
)
DISTKEY(pickup_date_id)
SORTKEY(pickup_date_id);