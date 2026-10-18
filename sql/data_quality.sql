-- ============================================================
-- PATENDIAMET IP ANALYTICS
-- Data Quality Assessment
-- ============================================================
--
-- Data source: Patendiamet "Leiutiste MYSQL" open-data extract
-- Snapshot: 14 October 2026
-- Database: patendiamet_analytics (MariaDB)
-- Source table: patent
--
-- Purpose:
-- Assess record coverage, missing values, chronological
-- consistency, identifier uniqueness, multi-valued fields,
-- and whitespace issues before analytical processing.
--
-- All queries are read-only and preserve the source data.
-- Findings are documented separately in README.md.
--
-- Important limitations:
-- The public extract does not necessarily contain all
-- applications submitted to Patendiamet.
-- Missing values may reflect administrative processes.
-- Queries using CURRENT_DATE() depend on execution date.
--
-- ============================================================


-- ============================================================
-- A. DATASET STRUCTURE AND COVERAGE (QUERIES 0-4)
-- ============================================================


-- 0. Total number of records
-- Establishes the dataset size as a baseline for subsequent
-- completeness checks and validation of exported datasets.
SELECT
    COUNT(*) AS total_rows
FROM patent;


-- 1. Record counts by type
-- Examines the composition of the dataset across original
-- source-system record types.
SELECT
    type,
    COUNT(*) AS n
FROM patent
GROUP BY type
ORDER BY n DESC;


-- 2. Record counts by status
-- Describes the overall frequency of administrative statuses.
-- Status meanings may differ between record types.
SELECT
    status,
    COUNT(*) AS n
FROM patent
GROUP BY status
ORDER BY n DESC;


-- 3. Record counts by type and status
-- Examines status distributions separately for each type.
-- Helps identify differences in administrative lifecycles.
SELECT
    type,
    status,
    COUNT(*) AS n

FROM patent
GROUP BY type, status
ORDER BY type, n DESC;


-- 4. Time coverage
-- Identifies the earliest and latest application and
-- registration dates represented in the source table.
-- Date ranges do not establish complete historical coverage.
SELECT
    MIN(application_date) AS earliest_application,
    MAX(application_date) AS latest_application,
    MIN(registration_date) AS earliest_registration,
    MAX(registration_date) AS latest_registration
FROM patent;


-- ============================================================
-- B. MISSINGNESS AND REGISTRATION-DATE CONSISTENCY (5-11)
-- ============================================================


-- 5. Overall missing-value counts
-- Counts NULL or empty values in selected key fields.
-- Missingness definitions depend on the individual field.
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
-- Expresses missing values as percentages of all records.
-- Complements the absolute counts from Query 5.
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
-- Identifies whether missingness is concentrated in
-- particular intellectual-property categories.
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
-- Uses type-specific denominators to make missingness
-- patterns comparable across differently sized categories.
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


-- 9. Missing registration dates by types and status
-- Investigates whether missing registration dates correspond
-- to pending, withdrawn, or other administrative statuses.
-- Missing registration dates are not automatically errors.
SELECT
    type,
    status,
    COUNT(*) AS n
FROM patent
WHERE registration_date IS NULL
GROUP BY type, status
ORDER BY type, n DESC;


-- 10. Inspect exceptional records with lapsed/revoked status
-- Inspects records with no registration date despite statuses
-- that may suggest a previously registered right.
-- Flags cases for review without assuming they are invalid.
SELECT
    id,
    application_number,
    registration_number,
    application_date,
    registration_date,
    status,
    type,
    name_estonian
FROM patent
WHERE registration_date IS NULL
  AND status IN ('revoked', 'lapsed')
ORDER BY type, status;


-- 11. Consistency between registration number and registration date
-- Examines records with a populated registration number
-- and checks whether the registration date is also present.
-- Identifies possible metadata inconsistencies.
SELECT
    type,
    COUNT(*) AS records_with_registration_number,
    SUM(registration_date IS NULL) AS missing_registration_date,
    ROUND(
        100.0 * SUM(registration_date IS NULL) / COUNT(*),
        3
    ) AS pct_missing_registration_date
FROM patent
WHERE registration_number IS NOT NULL
  AND registration_number <> ''
GROUP BY type;


-- ============================================================
-- C. CHRONOLOGICAL CONSISTENCY (QUERIES 12-16)
-- ============================================================


-- 12. Registration date before application date
-- Tests whether registration precedes the recorded
-- application date, potentially indicating an inconsistency.
SELECT
    COUNT(*) AS registration_before_application
FROM patent
WHERE registration_date IS NOT NULL
  AND application_date IS NOT NULL
  AND registration_date < application_date;


-- 13. Publication date before application date
-- Checks whether publication dates precede application dates.
-- Unexpected cases would require record-level inspection.
SELECT
    COUNT(*) AS publication_before_application
FROM patent
WHERE publication_date IS NOT NULL
  AND application_date IS NOT NULL
  AND publication_date < application_date;


-- 14. Decision date before application date
-- Checks the chronological ordering of application
-- and administrative decision dates.
SELECT
    COUNT(*) AS decision_before_application
FROM patent
WHERE decision_date IS NOT NULL
  AND application_date IS NOT NULL
  AND decision_date < application_date;


-- 15. Count future registration dates
-- Identifies registration dates later than the execution date.
-- Uses CURRENT_DATE(), so results change over time.
-- Future dates may represent scheduled administrative events.
SELECT
    COUNT(*) AS future_registration_dates
FROM patent
WHERE registration_date > CURRENT_DATE();


-- 16. Inspect future registration dates
-- Retrieves identifying information, dates, and statuses
-- for records flagged by Query 15.
-- Supports investigation without automatically classifying
-- future-dated records as erroneous.
SELECT
    id,
    type,
    application_number,
    registration_number,
    application_date,
    registration_date,
    status
FROM patent
WHERE registration_date > CURRENT_DATE()
ORDER BY registration_date;


-- ============================================================
-- D. IDENTIFIER UNIQUENESS AND DUPLICATION (QUERIES 17-26)
-- ============================================================


-- 17. Duplicate application numbers
-- Tests whether populated application numbers repeat
-- across records in the source table.
SELECT
    application_number,
    COUNT(*) AS n
FROM patent
WHERE application_number IS NOT NULL
  AND application_number <> ''
GROUP BY application_number
HAVING COUNT(*) > 1
ORDER BY n DESC, application_number;


-- 18. Duplicate registration numbers
-- Identifies repeated registration numbers across all types.
-- Repetition may reflect separate identifier namespaces.
SELECT
    registration_number,
    COUNT(*) AS n
FROM patent
WHERE registration_number IS NOT NULL
  AND registration_number <> ''
GROUP BY registration_number
HAVING COUNT(*) > 1
ORDER BY n DESC, registration_number;


-- 19. Duplicate European patent numbers
-- Checks the uniqueness of populated European patent
-- identifiers across source records.
SELECT
    eu_patent_number,
    COUNT(*) AS n
FROM patent
WHERE eu_patent_number IS NOT NULL
  AND eu_patent_number <> ''
GROUP BY eu_patent_number
HAVING COUNT(*) > 1
ORDER BY n DESC, eu_patent_number;


-- 20. Duplicate PCT application numbers
-- Identifies PCT identifiers linked to multiple records.
-- Shared PCT references do not necessarily imply duplicates.
SELECT
    pct_application_number,
    COUNT(*) AS n
FROM patent
WHERE pct_application_number IS NOT NULL
  AND pct_application_number <> ''
GROUP BY pct_application_number
HAVING COUNT(*) > 1
ORDER BY n DESC, pct_application_number;


-- 21. Count duplicate identifier values
-- Compares the number of repeated values across four
-- identifier fields, excluding NULL and empty values.
-- Counts duplicate groups rather than excess record rows.
SELECT
    'application_number' AS identifier,
    COUNT(*) AS duplicate_values
FROM (
    SELECT application_number
    FROM patent
    WHERE application_number IS NOT NULL
      AND application_number <> ''
    GROUP BY application_number
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT
    'registration_number',
    COUNT(*)
FROM (
    SELECT registration_number
    FROM patent
    WHERE registration_number IS NOT NULL
      AND registration_number <> ''
    GROUP BY registration_number
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT
    'eu_patent_number',
    COUNT(*)
FROM (
    SELECT eu_patent_number
    FROM patent
    WHERE eu_patent_number IS NOT NULL
      AND eu_patent_number <> ''
    GROUP BY eu_patent_number
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT
    'pct_application_number',
    COUNT(*)
FROM (
    SELECT pct_application_number
    FROM patent
    WHERE pct_application_number IS NOT NULL
      AND pct_application_number <> ''
    GROUP BY pct_application_number
    HAVING COUNT(*) > 1
) x;


-- 22. Inspect duplicated registration numbers
-- Displays a sample of records sharing registration numbers.
-- Supports investigation of cross-type identifier reuse.
SELECT
    registration_number,
    id,
    type,
    application_number,
    application_date,
    registration_date,
    status
FROM patent
WHERE registration_number IN (
    SELECT registration_number
    FROM patent
    WHERE registration_number IS NOT NULL
      AND registration_number <> ''
    GROUP BY registration_number
    HAVING COUNT(*) > 1
)
ORDER BY registration_number, type
LIMIT 40;


-- 23. Record types among duplicated registration numbers
-- Identifies which record types contain registrations
-- with non-unique numbers at the global dataset level.
SELECT
    type,
    COUNT(*) AS n
FROM patent
WHERE registration_number IN (
    SELECT registration_number
    FROM patent
    WHERE registration_number IS NOT NULL
      AND registration_number <> ''
    GROUP BY registration_number
    HAVING COUNT(*) > 1
)
GROUP BY type
ORDER BY n DESC;


-- 24. Inspect duplicated PCT application numbers
-- Compares records sharing PCT identifiers, including
-- national application numbers and ownership information.
-- Helps distinguish linked applications from duplicate rows.
SELECT
    pct_application_number,
    id,
    type,
    application_number,
    registration_number,
    application_date,
    status,
    owner
FROM patent
WHERE pct_application_number IN (
    SELECT pct_application_number
    FROM patent
    WHERE pct_application_number IS NOT NULL
      AND pct_application_number <> ''
    GROUP BY pct_application_number
    HAVING COUNT(*) > 1
)
ORDER BY pct_application_number, application_number;


-- 25. Duplicate registration numbers within record type
-- Tests uniqueness of the combined identifier:
-- (type, registration_number).
-- Accounts for potentially separate numbering systems.
SELECT
    type,
    registration_number,
    COUNT(*) AS n
FROM patent
WHERE registration_number IS NOT NULL
  AND registration_number <> ''
GROUP BY type, registration_number
HAVING COUNT(*) > 1
ORDER BY n DESC, type, registration_number;


-- 26. Duplicate PCT and national application combinations
-- Tests whether the same PCT identifier and national
-- application number combination occurs more than once.
-- A composite key can be more informative than PCT alone.
SELECT
    pct_application_number,
    application_number,
    COUNT(*) AS n
FROM patent
WHERE pct_application_number IS NOT NULL
  AND pct_application_number <> ''
GROUP BY pct_application_number, application_number
HAVING COUNT(*) > 1
ORDER BY n DESC;


-- ============================================================
-- E. MULTI-VALUED FIELDS AND TEXT STRUCTURE (QUERIES 27-35)
-- ============================================================


-- 27. Inspect priority_date values
-- Samples raw priority_date strings to understand their
-- structure and identify multiple entries in one field.
SELECT
    priority_date
FROM patent
WHERE priority_date IS NOT NULL
  AND priority_date <> ''
LIMIT 30;


-- 28. Count distinct priority_date values
-- Measures the number of populated and distinct complete
-- field strings, not distinct individual priority dates.
SELECT
    COUNT(*) AS non_missing_priority_date,
    COUNT(DISTINCT priority_date) AS distinct_priority_date
FROM patent
WHERE priority_date IS NOT NULL
  AND priority_date <> '';


--29. Inspect IPC classification values
-- Samples raw IPC fields to examine formatting and
-- determine whether multiple classifications are stored
-- in a single field.
SELECT
    ipc_class
FROM patent
WHERE ipc_class IS NOT NULL
  AND ipc_class <> ''
LIMIT 30;


-- 30. Inspect CPC classification values
-- Samples raw CPC fields to assess formatting,
-- completeness, and multiple classification entries.
SELECT
    cpc_class
FROM patent
WHERE cpc_class IS NOT NULL
  AND cpc_class <> ''
LIMIT 30;


-- 31. Maximum field lengths for awkward text fields
-- Identifies unusually long priority-date, IPC, and CPC
-- strings that may require special handling in Python.
SELECT
    MAX(CHAR_LENGTH(priority_date)) AS max_priority_date_length,
    MAX(CHAR_LENGTH(ipc_class)) AS max_ipc_class_length,
    MAX(CHAR_LENGTH(cpc_class)) AS max_cpc_class_length
FROM patent;


-- 32. Multiple priority dates
-- Uses comma presence as an indicator of multiple entries
-- in the priority_date field.
-- This does not validate or deduplicate individual dates.
SELECT
    COUNT(*) AS non_missing_priority_date,
    SUM(priority_date LIKE '%,%') AS multiple_priority_dates,
    ROUND(
        100.0 * SUM(priority_date LIKE '%,%') / COUNT(*),
        1
    ) AS pct_multiple_priority_dates
FROM patent
WHERE priority_date IS NOT NULL
  AND TRIM(priority_date) <> '';


-- 33. Multiple IPC and CPC classifications
-- Counts populated classification fields and records
-- containing comma-separated classification entries.
-- Results inform the normalization strategy in Python.
SELECT
    SUM(ipc_class IS NOT NULL AND TRIM(ipc_class) <> '')
        AS non_missing_ipc,

    SUM(ipc_class LIKE '%,%')
        AS multiple_ipc,

    SUM(cpc_class IS NOT NULL AND TRIM(cpc_class) <> '')
        AS non_missing_cpc,

    SUM(cpc_class LIKE '%,%')
        AS multiple_cpc
FROM patent;


-- 34. Inspect longest priority_date values
-- Retrieves records with the longest priority_date strings.
-- Displays a shortened preview for manual inspection.
SELECT
    id,
    type,
    application_number,
    CHAR_LENGTH(priority_date) AS field_length,
    LEFT(priority_date, 200) AS priority_date_preview
FROM patent
WHERE priority_date IS NOT NULL
ORDER BY CHAR_LENGTH(priority_date) DESC
LIMIT 5;


-- 35. Count priority_date entries per record
-- Estimates the number of comma-separated entries
-- using delimiter counts.
-- Repeated dates may inflate counts of unique dates.
SELECT
    id,
    type,
    application_number,
    CHAR_LENGTH(priority_date) AS field_length,
    1 + CHAR_LENGTH(priority_date)
      - CHAR_LENGTH(REPLACE(priority_date, ',', ''))
      AS number_of_entries
FROM patent
WHERE priority_date IS NOT NULL
  AND TRIM(priority_date) <> ''
ORDER BY number_of_entries DESC
LIMIT 10;


-- ============================================================
-- F. FINAL FORMAT AND WHITESPACE VALIDATION (QUERY 36)
-- ============================================================


-- 36. Whitespace and blank-value checks
-- Checks key identifier and categorical fields for
-- NULL values, blank strings, and surrounding whitespace.
-- Confirms whether further string cleaning is necessary.
SELECT
    COUNT(*) AS total_rows,

    SUM(type IS NULL OR TRIM(type) = '')
        AS missing_type,

    SUM(status IS NULL OR TRIM(status) = '')
        AS missing_status,

    SUM(application_number IS NULL
        OR TRIM(application_number) = '')
        AS missing_application_number,

    SUM(CHAR_LENGTH(type) <> CHAR_LENGTH(TRIM(type)))
        AS type_with_outer_spaces,

    SUM(CHAR_LENGTH(status) <> CHAR_LENGTH(TRIM(status)))
        AS status_with_outer_spaces,

    SUM(CHAR_LENGTH(application_number)
        <> CHAR_LENGTH(TRIM(application_number)))
        AS application_number_with_outer_spaces

FROM patent;

