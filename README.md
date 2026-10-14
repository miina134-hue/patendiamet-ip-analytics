# Patendamet IP Analytics Project

## Objective

Build an end-to-end analytical workflow using Patendiamet open data to demonstrate practical skills in SQL, data quality, Python, database work, business analysis, and Power BI.

The project focuses on undestanding intellectual-property records, assessing data quality, identifying meaningful trends, and turning raw administrative data into decision-supporting outputs.

## Data source

The project uses Patendiamet's public open data SQL dump from:
'https://leiutised.epa.ee/avalik/openData'

The source dump is imported into a local MariaDB database for analysis.

Raw database dumps are not stored in the Git repository. Instead, the repository documents the source and processing workflow.

## Planned workflow

Patendiamet open data SQL dump
→ MariaDB database
→ SQL data-quality checks
→ SQL business analysis
→ Python/pandas exploratory analysis
→ Power BI dashboard
→ Automated data refresh
→ Optional external API enrichment

## Tools

- Git
- MariaDB
- SQL
- Python
- pandas
- Power BI

## Current progress
- Initialized Git repository and project structure.
- Downloaded the latest Patendiamet open data SQL dump.
- Imported the dump into a local MariaDB database.
- Loaded 34,223 records from the `patent` table.
- Explored record types and status distributions.
- Added time-coverage checks.
- Added overall missing-value checks.
- Added type-specific missingness analysis.
- Documented initial data quality findings.

## Initial data quality observations
Initial profiling shows that missing values are strongly dependent on record type.

For example:
- CPC classification is missing for most 'EuPatent' records, while IPC classification is almost complete for the same type. 
- 'AdditionalProtection' records also have substantially more missing IPC and author information than the other record types.

This suggests that high missingness does not automatically indicate poor data quality. Some fields appear to be structurally relevent only
to certain intellectual-property record types or are not populated consistently across all processes.

For this reason, missingness is evaluated by 'type' and 'status' before deciding whether a field represets a genuine data-quality issue.

## Next steps
1. Investigate missing `registration_date` values by status.
2. Check future and chronologically inconsistent dates.
3. Check duplicate identifiers.
4. Inspect `priority_date`, IPC and CPC formats.
5. Create `sql/analysis.sql` with business-facing analytical queries.
6. Connect Python/pandas to MariaDB and create derived analytical fields.
7. Perform exploratory analysis in Python.
8. Automate retrieval of the newest Patendiamet open-data dump.
9. Build a repeatable database refresh workflow.
10. Build a Power BI dashboard.
11. Finalize project documentation.
12. Optionally enrich selected records using an external patent API such as EPO OPS.
(CPC classifications for 50-100 records.)
