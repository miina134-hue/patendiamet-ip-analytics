# ============================================================
# PATENDIAMET IP ANALYTICS
# Data Extraction and Transformation
# ============================================================
#
# Data source: Patendiamet public open-data extract
# Snapshot: 14 October 2026
# Database: patendiamet_analytics (MariaDB)
# Source table: patent
#
# Purpose:
# Extract the source records into pandas and validate
# their completeness and basic structure.
#
# Database credentials are entered interactively.
# The original database records are not modified.
#
# ============================================================

from getpass import getpass

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


# ------------------------------------------------------------
# 1. Connect to MariaDB
# ------------------------------------------------------------


url = URL.create(
    drivername="mysql+pymysql",
    username="root",
    password=getpass("MariaDB password: "),
    host="127.0.0.1",
    port=3306,
    database="patendiamet_analytics",
)

engine = create_engine(url)


# ------------------------------------------------------------
# 2. Extract source data
# ------------------------------------------------------------


try:
    with engine.connect() as connection:
        df = pd.read_sql_query(
            text("SELECT * FROM patent"),
            connection
        )
finally:
    engine.dispose()


# ------------------------------------------------------------
# 3. Validate extracted data
# ------------------------------------------------------------


print("\nDATASET STRUCTURE")
print(f"Total records: {len(df):,}")
print(f"Total columns: {len(df.columns)}")
print(f"Unique record IDs: {df['id'].nunique():,}")

assert len(df) == 34223, "Unexpected record count"
assert len(df.columns) == 41, "Unexpected column count"
assert df["id"].is_unique, "Duplicate record IDs detected"
assert df["id"].notna().all(), "Missing record IDs detected"


# ------------------------------------------------------------
# 4. Examine record composition and missingness
# ------------------------------------------------------------


print("\nRECORDS BY TYPE")
print(df["type"].value_counts().to_string())

print("\nMISSING REGISTRATION DATES")
print(f"Missing: {df['registration_date'].isna().sum():,}")

print("\nInitial extraction and validation successful!")



# ------------------------------------------------------------
# 5. Prepare application-to-registration intervals
# ------------------------------------------------------------


# Work on a copy to preserve the original extracted data.
intervals = df[
    ["id", "type", "application_date", "registration_date"]
].copy()

# Convert source dates into pandas datetime values.
intervals["application_date"] = pd.to_datetime(
    intervals["application_date"],
    errors="coerce"
)

intervals["registration_date"] = pd.to_datetime(
    intervals["registration_date"],
    errors="coerce"
)

# Match the eligibility rules used in SQL Query 10:
# - Both dates must be present.
# - Registration must not precede application.
# - Registration occurred between 2018 and 2025.

valid_intervals = (
    intervals["application_date"].notna()
    & intervals["registration_date"].notna()
    & (
        intervals["registration_date"]
        >= intervals["application_date"]
    )
    & (
        intervals["registration_date"]
        >= pd.Timestamp("2018-01-01")
    )
    & (
        intervals["registration_date"]
        < pd.Timestamp("2026-01-01")
    )
)

intervals = intervals.loc[valid_intervals].copy()

# Calculate the number of days between the two dates.
# Match MariaDB DATEDIFF() by comparing calendar dates.
# Ignore any time-of-day components in the source fields.
intervals["interval_days"] = (
    intervals["registration_date"].dt.normalize()
    - intervals["application_date"].dt.normalize()
).dt.days

print("\nREGISTRATION INTERVAL DATASET")
print(f"Eligible records: {len(intervals):,}")


# ------------------------------------------------------------
# 6. Summarize registration intervals by record type
# ------------------------------------------------------------


interval_summary = (
    intervals
    .groupby("type")
    .agg(
        record_count=("interval_days", "size"),
        mean_days=("interval_days", "mean"),
        median_days=("interval_days", "median"),
        min_days=("interval_days", "min"),
        max_days=("interval_days", "max"),
    )
    .sort_values("record_count", ascending=False)
)

# Convert the mean and median intervals into years.
interval_summary["mean_years"] = (
    interval_summary["mean_days"] / 365.25
).round(1)

interval_summary["median_years"] = (
    interval_summary["median_days"] / 365.25
).round(1)

print("\nAPPLICATION-TO-REGISTRATION INTERVALS BY TYPE")

print(
    interval_summary[
        [
            "record_count",
            "mean_years",
            "median_years",
            "min_days",
            "max_days",
        ]
    ].to_string()
)



# ------------------------------------------------------------
# 7. Normalize multi-valued IPC classifications
# ------------------------------------------------------------


# Create a separate table while preserving the original data.
# Keep only records with a populated IPC classification field.

ipc_source = df.loc[
    df["ipc_class"].fillna("").str.strip().ne(""),
    ["id", "ipc_class"]
].copy()

# Count records with multiple classifications.
multiple_ipc = ipc_source["ipc_class"].str.contains(
    ",", regex=False
).sum()

# Split comma-separated classifications into lists.
ipc_codes = ipc_source.assign(
    ipc_code=ipc_source["ipc_class"].str.split(",")
)

# Create one row per individual classification.
ipc_codes = ipc_codes.explode(
    "ipc_code", ignore_index=True
)

# Remove surrounding whitespace.
ipc_codes["ipc_code"] = ipc_codes["ipc_code"].str.strip()

# Exclude empty classification entries.
ipc_codes = ipc_codes.loc[
    ipc_codes["ipc_code"].notna()
    & ipc_codes["ipc_code"].ne(""),
    ["id", "ipc_code"]
].copy()

# Identify repeated patent-classification pairs.
duplicate_pairs = ipc_codes.duplicated(
    subset=["id", "ipc_code"]
).sum()

# Retain one row per unique patent-classification pair.
ipc_codes = (
    ipc_codes
    .drop_duplicates(subset=["id", "ipc_code"])
    .sort_values(["id", "ipc_code"])
    .reset_index(drop=True)
)


# ------------------------------------------------------------
# 8. Validate normalized IPC classifications
# ------------------------------------------------------------


print("\nIPC CLASSIFICATION NORMALIZATION")

print(f"Records with IPC data: {len(ipc_source):,}")
print(f"Records with multiple IPC values: {multiple_ipc:,}")
print(f"Normalized IPC assignments: {len(ipc_codes):,}")
print(f"Unique patent IDs: {ipc_codes['id'].nunique():,}")
print(f"Repeated pairs removed: {duplicate_pairs:,}")

# Every record with IPC data must remain represented.
assert ipc_codes["id"].nunique() == len(ipc_source), (
    "Some records with IPC data were lost during normalization"
)

# Every classification must contain a nonempty value.
assert ipc_codes["ipc_code"].notna().all()
assert ipc_codes["ipc_code"].ne("").all()

# Each patent-classification combination must be unique.
assert not ipc_codes.duplicated(
    subset=["id", "ipc_code"]
).any()

# Check that the original dataset remains unchanged.
assert len(df) == 34223

print("\nSAMPLE OF NORMALIZED IPC DATA")
print(ipc_codes.head(10).to_string(index=False))

print("\nIPC normalization and validation successful!")



