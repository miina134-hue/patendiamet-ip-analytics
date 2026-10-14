-- Patendiamet IP Analytics
-- Initial structure and data-quality exploration

-- 0. Total number of records
SELECT
    COUNT(*) AS total_rows
FROM patent;

-- 1. Record counts by type
SELECT
    type,
    COUNT(*) AS n
FROM patent
GROUP BY type
ORDER BY n DESC;

-- 2. Record counts by status
SELECT
    status,
    COUNT(*) AS n
FROM patent
GROUP BY status
ORDER BY n DESC;

-- 3. Record counts by type and status
SELECT
    type,
    status,
    COUNT(*) AS n

FROM patent
GROUP BY type, status
ORDER BY type, n DESC;

-- 4. Time coverage
SELECT
    MIN(application_date) AS earliest_application,
    MAX(application_date) AS latest_application,
    MIN(registration_date) AS earliest_registration,
    MAX(registration_date) AS latest_registration
FROM patent;

-- 5. Overall missing-value counts
SELECT
    COUNT(*) AS total_rows,
    SUM(application_number IS NULL) AS missing_application_number,
    SUM(application_date IS NULL) AS missing_application_date,
    SUM(registration_date IS NULL) AS missing_registration_date,
    SUM(status IS NULL OR status = '') AS missing_status,
    SUM(ipc_class IS NULL OR ipc_class = '') AS missing_ipc_class,
    SUM(cpc_class IS NULL OR cpc_class = '') AS missing_cpc_class,
    SUM(owner IS NULL OR owner = '') AS missing_owner,
    SUM(author IS NULL OR author = '') AS missing_author
FROM patent;

-- 6. Overall missing-value percentages
SELECT
    ROUND(
        100.0 * SUM(application_number IS NULL) / COUNT(*),
        1
    ) AS pct_missing_application_number,

    ROUND(
        100.0 * SUM(application_date IS NULL) / COUNT(*),
        1
    ) AS pct_missing_application_date,

    ROUND(
        100.0 * SUM(registration_date IS NULL) / COUNT(*),
        1
    ) AS pct_missing_registration_date,

    ROUND(
        100.0 * SUM(status IS NULL OR status = '') / COUNT(*),
        1
    ) AS pct_missing_status,

    ROUND(
        100.0 * SUM(ipc_class IS NULL OR ipc_class = '') / COUNT(*),
        1
    ) AS pct_missing_ipc_class,

    ROUND(
        100.0 * SUM(cpc_class IS NULL OR cpc_class = '') / COUNT(*),
        1
    ) AS pct_missing_cpc_class,

    ROUND(
        100.0 * SUM(owner IS NULL OR owner = '') / COUNT(*),
        1
    ) AS pct_missing_owner,

    ROUND(
        100.0 * SUM(author IS NULL OR author = '') / COUNT(*),
        1
    ) AS pct_missing_author
FROM patent;

-- 7. Missing-value counts by record type
SELECT
    type,
    COUNT(*) AS n,
    SUM(registration_date IS NULL) AS missing_registration_date,
    SUM(ipc_class IS NULL OR ipc_class = '') AS missing_ipc_class,
    SUM(cpc_class IS NULL OR cpc_class = '') AS missing_cpc_class,
    SUM(author IS NULL OR author = '') AS missing_author
FROM patent
GROUP BY type
ORDER BY n DESC;

-- 8. Missing-value percentages by record type
SELECT
    type,
    COUNT(*) AS n,

    ROUND(
        100.0 * SUM(registration_date IS NULL) / COUNT(*),
        1
    ) AS pct_missing_registration_date,

    ROUND(
        100.0 * SUM(ipc_class IS NULL OR ipc_class = '') / COUNT(*),
        1
    ) AS pct_missing_ipc_class,

    ROUND(
        100.0 * SUM(cpc_class IS NULL OR cpc_class = '') / COUNT(*),
        1
    ) AS pct_missing_cpc_class,

    ROUND(
        100.0 * SUM(author IS NULL OR author = '') / COUNT(*),
        1
    ) AS pct_missing_author

FROM patent
GROUP BY type
ORDER BY n DESC;
