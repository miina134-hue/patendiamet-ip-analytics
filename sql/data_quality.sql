-- Patendiamet IP Analytics
-- Initial structure and data-quality exploration

-- 0. Total number od records
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

