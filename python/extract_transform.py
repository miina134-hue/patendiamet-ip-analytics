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



