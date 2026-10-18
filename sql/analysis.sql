-- ============================================================
-- Patendiamet IP Analytics: business analysis queries
-- Source: Patendiamet "Leiutiste MYSQL" dump (2026-10-14 snapshot)
-- Database: patendiamet_analytics | Source table: patent
-- ============================================================
-- Important interpretation notes:
-- * These queries count records in the downloaded extract; they
--   do not necessarily count every IP application filed in Estonia.
-- * 'application_date' and 'registration_date' capture different
--   events, especially for European patents.
-- * The registration interval is a difference between database
--   fields, NOT an official Patendiamet processing-time KPI.
-- * 2026 is incomplete in this snapshot; recent application-year
--   cohorts may also be underrepresented due to administrative lags.
-- * The analyses do not modify the original patent table.


-- 1. Annual record counts by application year
-- Shows the distribution of current extract records by application year.
SELECT
    YEAR(application_date) AS application_year,
    COUNT(*) AS record_count
FROM patent
WHERE application_date IS NOT NULL
GROUP BY YEAR(application_date)
ORDER BY application_year;


-- 2. Annual record counts by intellectual property type
-- Disaggregates the annual series because IP types follow different processes.
SELECT
    YEAR(application_date) AS application_year,
    type,
    COUNT(*) AS record_count
FROM patent
WHERE application_date IS NOT NULL
GROUP BY
    YEAR(application_date),
    type
ORDER BY
    application_year,
    type;


-- 3. Year-over-year changes by record type
-- LAG() compares each type with its preceeding observed application year.
-- Growth is reported only if that preceding year is consecutive.
-- Earlier years remain in the CTE so 2018 can be compared with 2017.
WITH yearly_counts AS (
    SELECT
        YEAR(application_date) AS application_year,
        type,
        COUNT(*) AS record_count
    FROM patent
    WHERE application_date IS NOT NULL
    GROUP BY YEAR(application_date), type
),
yearly_comparison AS (
    SELECT
        application_year,
        type,
        record_count,
        LAG(application_year) OVER (
            PARTITION BY type
            ORDER BY application_year
        ) AS previous_year,
        LAG(record_count) OVER (
            PARTITION BY type
            ORDER BY application_year
        ) AS previous_count
    FROM yearly_counts
)
SELECT
    application_year,
    type,
    record_count,
    previous_count,
    CASE
        WHEN previous_year = application_year - 1
        THEN ROUND(
            100.0 * (record_count - previous_count)
            / NULLIF(previous_count, 0),
            1
        )
        ELSE NULL
    END AS yoy_change_pct
FROM yearly_comparison
WHERE application_year BETWEEN 2018 AND 2024
ORDER BY type, application_year;


-- 4. Monthly record counts by application date, 2022-2024
-- An aggregate monthly series. Months with zero records would not appear.
SELECT
    YEAR(application_date) AS application_year,
    MONTH(application_date) AS application_month,
    COUNT(*) AS record_count
FROM patent
WHERE application_date >= '2022-01-01'
  AND application_date < '2025-01-01'
GROUP BY
    YEAR(application_date),
    MONTH(application_date)
ORDER BY
    application_year,
    application_month;


-- 5. Monthly record counts by type, 2022-2024
-- Uses conditional aggregation for easy comparison of each type.
-- For a Power BI model, a long-format date/type/count table may be preferable.
SELECT
    DATE_FORMAT(application_date, '%Y-%m') AS application_month,

    SUM(CASE WHEN type = 'EuPatent'
        THEN 1 ELSE 0 END) AS eu_patent,

    SUM(CASE WHEN type = 'DesignApplication'
        THEN 1 ELSE 0 END) AS design_application,

    SUM(CASE WHEN type = 'UtilityModel'
        THEN 1 ELSE 0 END) AS utility_model,

    SUM(CASE WHEN type = 'AdditionalProtection'
        THEN 1 ELSE 0 END) AS additional_protection,

    COUNT(*) AS total_records
FROM patent
WHERE application_date >= '2022-01-01'
  AND application_date < '2025-01-01'
GROUP BY DATE_FORMAT(application_date, '%Y-%m')
ORDER BY application_month;


-- 6. European patent records by registration year, 2018-2025
-- Compared with application-year counts to assess date-field differences.
SELECT
    YEAR(registration_date) AS registration_year,
    COUNT(*) AS record_count
FROM patent
WHERE type = 'EuPatent'
  AND registration_date >= '2018-01-01'
  AND registration_date < '2026-01-01'
GROUP BY YEAR(registration_date)
ORDER BY registration_year;


-- 7. European patent application-to-registration interval by registration year
-- An observed interval between two source dates, not oficial processing time.
-- Includes only records with a registration date in 2018-2025.
SELECT
    YEAR(registration_date) AS registration_year,
    COUNT(*) AS record_count,
    ROUND(
        AVG(DATEDIFF(registration_date, application_date)),
        0
    ) AS avg_days_between_dates,
    ROUND(
        AVG(DATEDIFF(registration_date, application_date)) / 365.25,
        1
    ) AS avg_years_between_dates,
    MIN(DATEDIFF(registration_date, application_date)) AS min_days,
    MAX(DATEDIFF(registration_date, application_date)) AS max_days
FROM patent
WHERE type = 'EuPatent'
  AND application_date IS NOT NULL
  AND registration_date IS NOT NULL
  AND registration_date >= application_date
  AND registration_date >= '2018-01-01'
  AND registration_date < '2026-01-01'
GROUP BY YEAR(registration_date)
ORDER BY registration_year;


-- 8. Status distribution within each record type
-- Percentages are calculated within type; these are current statuses,
-- not application success rates or status-transition probabilities.
WITH status_counts AS (
    SELECT
        type,
        status,
        COUNT(*) AS record_count
    FROM patent
    GROUP BY type, status
)
SELECT
    type,
    status,
    record_count,
    ROUND(
        100.0 * record_count /
        SUM(record_count) OVER (PARTITION BY type),
        1
    ) AS pct_within_type
FROM status_counts
ORDER BY type, record_count DESC;


-- 9. Annual registration activity by type, 2018-2025
-- Counts are drawn from the snapshot; the meaning of registration_date
-- may differ by type. Records without registration_dates are excluded.
SELECT
    YEAR(registration_date) AS registration_year,
    type,
    COUNT(*) AS record_count
FROM patent
WHERE registration_date >= '2018-01-01'
  AND registration_date < '2026-01-01'
GROUP BY
    YEAR(registration_date),
    type
ORDER BY
    registration_year,
    type;


-- 10. Application-to-registration intervals by record type 2018-2025
-- Observed intervals only, excluding unregistered/missing-date records.
-- Means may be influenced by long intervals; medians are calculated
-- separately in Python for comparison.
SELECT
    type,
    COUNT(*) AS record_count,
    ROUND(
        AVG(DATEDIFF(registration_date, application_date)),
        0
    ) AS avg_days_between_dates,
    ROUND(
        AVG(DATEDIFF(registration_date, application_date)) / 365.25,
        1
    ) AS avg_years_between_dates,
    MIN(DATEDIFF(registration_date, application_date)) AS min_days,
    MAX(DATEDIFF(registration_date, application_date)) AS max_days
FROM patent
WHERE application_date IS NOT NULL
  AND registration_date IS NOT NULL
  AND registration_date >= application_date
  AND registration_date >= '2018-01-01'
  AND registration_date < '2026-01-01'
GROUP BY type
ORDER BY record_count DESC;
 
