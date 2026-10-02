-- dim_location: loaded from TLC's Taxi Zone Lookup Table
COPY dim_location
FROM 's3://raw-zone-889387846031-us-east-2-an/lookup/taxi_zones.csv'
IAM_ROLE default
CSV
IGNOREHEADER 1
REGION 'us-east-2';

-- dim_vendor: only two vendors in TLC's data dictionary
INSERT INTO dim_vendor (vendor_id, vendor_name) VALUES
(1, 'Creative Mobile Technologies'),
(2, 'Curb Mobility');

-- dim_date: generated for exactly June 1-30, 2026 (matching the Glue job's filter)
INSERT INTO dim_date (date_id, full_date, year, month, day, day_of_week, is_weekend)
SELECT
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INT) AS date_id,
    d AS full_date,
    EXTRACT(YEAR FROM d) AS year,
    EXTRACT(MONTH FROM d) AS month,
    EXTRACT(DAY FROM d) AS day,
    TO_CHAR(d, 'Day') AS day_of_week,
    CASE WHEN EXTRACT(DOW FROM d) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend
FROM (
    SELECT '2026-06-01'::DATE AS d
    UNION ALL SELECT '2026-06-02'::DATE
    UNION ALL SELECT '2026-06-03'::DATE
    UNION ALL SELECT '2026-06-04'::DATE
    UNION ALL SELECT '2026-06-05'::DATE
    UNION ALL SELECT '2026-06-06'::DATE
    UNION ALL SELECT '2026-06-07'::DATE
    UNION ALL SELECT '2026-06-08'::DATE
    UNION ALL SELECT '2026-06-09'::DATE
    UNION ALL SELECT '2026-06-10'::DATE
    UNION ALL SELECT '2026-06-11'::DATE
    UNION ALL SELECT '2026-06-12'::DATE
    UNION ALL SELECT '2026-06-13'::DATE
    UNION ALL SELECT '2026-06-14'::DATE
    UNION ALL SELECT '2026-06-15'::DATE
    UNION ALL SELECT '2026-06-16'::DATE
    UNION ALL SELECT '2026-06-17'::DATE
    UNION ALL SELECT '2026-06-18'::DATE
    UNION ALL SELECT '2026-06-19'::DATE
    UNION ALL SELECT '2026-06-20'::DATE
    UNION ALL SELECT '2026-06-21'::DATE
    UNION ALL SELECT '2026-06-22'::DATE
    UNION ALL SELECT '2026-06-23'::DATE
    UNION ALL SELECT '2026-06-24'::DATE
    UNION ALL SELECT '2026-06-25'::DATE
    UNION ALL SELECT '2026-06-26'::DATE
    UNION ALL SELECT '2026-06-27'::DATE
    UNION ALL SELECT '2026-06-28'::DATE
    UNION ALL SELECT '2026-06-29'::DATE
    UNION ALL SELECT '2026-06-30'::DATE
) sub;