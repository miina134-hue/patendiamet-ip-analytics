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

### Registration-date consistency
Most missing 'registration_date' values are concentrated in lifecycle statuses such as pending, withdrawn, rejected, deemed withdrawn, terminated, or not validated.
This suggests that the majority of missing registration dates are structurally consistent with the underlying process rather than general data-quality failures.

A small number of records with 'lapsed' or 'revoked' status also lack a registration date and were inspected separately.
One 'EuPatent' record contains a registration number but no registration date.

Across records with a non-missing 'registration_number', this inconsistency occurs only once, indicating a rare record-evel exception or a special business-process case
that would require domain validation before being classified as an error.

### Chronological consistency
No records were found where 'registration_date', 'publication_date', or 'decision_date' preceedes 'application_date'.

Nine 'EuPatent' records have a future 'registration_date' of 2026-11-16. All nine have status 'validatedInEstonia', suggesting that the future date may
represent a scheduled or effective business-process date rather than a random data-entry error. These records are therefore flagged for domain validation
rather than treated as confirmed data-quality problems.

### Identifier consistency
'application_number' and 'eu_patent_number' are unique across the dataset.

'registration_number' is not globally unique, but duplicate values occur ascross different record types.
No duplicates remain when 'registration_number' is evaluated together with 'type', suggesting that registration numbers use type-specific namespaces.

Repeated 'pct_application_number' values correspond to different national 'application_number' values. This indicates a legitimate one-to-many relationship
between an international/PCT filling and national records rather than duplicated observations.

### Multi-valued fields and formatting
The database contains several fields storing multiple values as comma-separated text.


Initial analysis identified:

- 'priority_date': 7,766 of 29,625 populated records (26.2%) contain multiple entries.
- 'ipc_class': 27,064 of 33,629 populated records (80.5%) contain multiple entries.
- 'cpc_class': 2,273 of 2,732 populated records (83.2%) contain multiple entries.

Further inspection identified unusually long lists of priority dates. The longest field contains 91 comma-separated
entries across 1,090 characters.

Some records contain extensive repetitions of identical dates.

The number of entries does not necessarily represent the number of distinct priority dates. Further processing is
required to distinguish unique dates from repeated entries.

The original values will be preserved, and Python will be used to create normalized analytical representations.

### Structural and formatting consistency
A final structural check was performed on all 34,223 records.

No missing, empty, or whitespace only values were found in the 'type', 'status', or 'application_number' fields.

No leading or trailing spaces were detected in these fields either.

These results indicate that the key identifying and categorical fields are consistent with respest to basic completeness and whitespace formatting.

## Preliminary analytical findings
The following findings are based on Patendiamet's public open-data extract downloaded on 14 October 2026.

The analysis describes records contained in the extract. These should not automatically be interpreted as complete annual application or registration statistics, 
as database coverage depends on publication requirements and administrative processes.

1. Annual record counts by application year
The dataset contains records with application dates ranging from 1994 to 2026.

Annual record counts fluctuate substantially, reaching a maximum of 2,086 in 2003. Counts are considerably lower in recent application years.

However, recent application years may be underrepresented because the extract contains records that have reached particular administratice or publication stages.
The year 2026 is also incomplete.

2. Annual record trens by intellectual-property type
The distribution of records differs considerably across intellectual-property types.

EuPatent records dominate much of the period following 2002, accounting for 1,986 of the 2,086 records with application dates in 2003.

The other record types follow different patterns and have substantially smaller annual counts.

This indicates that overall trends are strongly influenced by the composition of the dataset. Analyses should therefore distinguish intellectual-property record types.

Note: Original database type codes are retained in the analysis. Their precise administrative definitions should be checked againt Patendiamet's documentation.

3. Year-over-year changes by record type
Year-over-year comparisons reveal substantial differences between record types.

European patent record counts declined in every year from 2018 to 2024, fallinf from 860 to 28.

Other categories show greater relative volatility. For example, DesignApplication record increased by 122.2% in 2023, representing an increase from 9 to 20 records.

Percentage changes based on small denominators should be interpreted alongside absolute counts.

These trends describe records contained in the current extract rather than necessarily representing changes in underlying intellectual property filing activity.

4. Monthly record trends (2022-2024)
Monthly analysis covers all 36 months from January 2022 to December 2024, with no zero-count months observed.

Year     Record count

2022     254

2023     168

2024     108

Monthly fluctuations were observed, but no consistent seasonal pattern was identified across the three years.

The relatively small number of monthly records limits the reliability of conclusins about seasonality.

5. Monthly trends by intellectual-property type
Disaggregating monthly record counts reveals that the overall decline between 2022 and 2024 is driven almost entirely by European patent records.

European patent record counts decreased by 149, while the combined count for the other three record types increased from 77 to 80.

Consequently, the overall decline does not reflect a uniform decrease across all record types.

Recent European patent application years may be affected by administrative delays and the database's inclusion criteria.

6. European patent records by registration year
Grouping EuPatent records by registration_date produces a different historical distribution from grouping them by application_date.

Registration-year counts decreased from 1,930 in 2018 to 637 in 2024, followed by an increase to 731 in 2025.

The application-year series exhibits a substantially sharper decline across recent years.

The two series represent different cohorts: records registered in a particular year may have original application dates several years earlier.

Consequently, application-year and registration-year counts should not be treated as interchangeable indicators.

The continuing decline in registration-year counts also suggests that application-to-registration delays alone cannot explain all observed trends.

7. European patent application-to-registration intervals
Analysis of EuPatent records registered between 2018 and 2025 reveals substantial intervals between the recorded application and registration dates.

Average intervals range from approximately 5.8 to 6.8 years across registration-year cohorts.

These substantial intervals help explain why recent application years contain relatively few European patent records in the public extract.

However, the intervals represent differences between database fields and should not be interpreted as Patendiamet's own administrative processing times. European patent examination and other procedures may account for substantial portions of the interval.

The analysis is also restricted to records with observed registration dates, and average intervals may be influenced by unusually long observations or changes in cohort composition.

Further Python analysis will examine median intervals and the distribution of observations.

8. Current status distributions by record type
The distribution of recorded statuses differs substantially across intellectual-property types.

Status distributions reflect the composition and administrative history of records included in the snapshot. 
They should not be interpreted as application success rates, rejection probabilities, or indicators of Patendiamet's operational performance.

The status distributions also help explain some of the missing registration dates identified during data-quality assessment. 
Missing values may reflect administrative lifecycle stages rather than data-entry errors.

The original type label DesignApplication is retained. Evidence from official statistics suggests that it relates to national patent applications rather than industrial designs; 
the source-system definition should be verified before assigning a final business-facing label.


9. Annual registration activity by record type (2018-2025)
Registration-year analysis reveals substantial differences across intellectual-property types.

European patent records dominate the annual counts. Their number decreased by approximately 67.0% between 2018 and 2024, followed by a 14.8% increase in 2025.

By comparison, the three other record types together accounted for 74 records in 2018 and 79 in 2024. 
Their combined registration-year counts were therefore relatively stable between these endpoints.

The overall decline in registration-year counts is primarily associated with EuPatent records rather than a uniform decrease across intellectual-property types.

10. Application-to-registration intervals by record type
The interval between application_date and registration_date was calculated for records registered between 2018 and 2025, 
excluding records with missing dates or registration dates preceding application dates.

European patent records exhibit considerably longer average intervals than the other intellectual-property types.

The substantial difference helps explain why recent European patent application-year cohorts are sparsely represented in the public database extract.

The results support analysing registration intervals separately by record type rather than combining them into a single operational performance indicator.

A planned Python analysis will calculate median intervals and examine their distributions to complement these descriptive averages.

#### Interpretation and data-coverage limitations

The analysis highlights several important limitations:

Publicly available records do not necessarily cover all applications received by Patendiamet.

Different intellectual-property types follow different administrative processes.

Application dates and registration dates represent different events and cohorts.

Recent application years may be underrepresented because of publication and registration delays.

Annual record counts should not be interpreted directly as indicators of innovation or patenting activity without validation against official statistics.

## Python validation of registration intervals
The SQL application-to-registration interval analysis was reproduced in Python using pandas.

All 10,848 eligible records were retained, and record counts and mean intervals matched the earlier SQL results.

Median intervals were also calculated which are lower than mean intervals across all four types, suggesting that longer observations influence the averages.

These results describe intervals betweem recorded database dates, not verified Patendiamet processing times. The analysis is restricted to records registered during 2018-2025
with valid application and registration dates.

## Python data processing
The Python pipeline is implemented in python/extract_transform.py using Python 3.13, pandas, SQLAlchemy and PyMySQL.

It extract records from the local MariaDB database, validates their structure, calculates registration intervals, normalizes IPC classifications and exports datasets for Power BI.

## Data extraction and validation
The extracted dataset contains 34,223 records and 41 columns, including 34,223 unique record IDs.

The Python validation reproduces key findings from the SQL assessment, including 2,966 records with missing registration dates. Original database records are not modified.

## Application-to-registration intervals
Registration intervals are calculated as differences between recorded calendar dates for records registered during 2018-2025, excluding records with missing or chronologically inconsistent dates.

A total of 10,848 records meet these criteria.

| Record type | Mean interval | Median interval |
|---|---:|---:|
| EuPatent | 6.1 years | 5.2 years |
| UtilityModel | 1.5 years | 1.2 years |
| AdditionalProtection | 2.1 years | 1.5 years |
| DesignApplication | 2.8 years | 2.6 years |

The medians are lower than the means, consistent with longer observations influencing the averages.

These are descriptive intervals between database fields, not measures of Patendiamet's own administrative processing time.

## IPC classification normalization
The ipc_class field contains multiple comma-separated classifications for many records.

Python separates the codes into individual patent-classification assignments, strips surrounding whitespace and removes repeated assignment within the same patent.

The resulting normalized table contains:
- 33,629 unique patent IDs
- 131,929 unique patent-IPC assignments
- 63 repeated assignment removed during normalization

The original 34,223-record dataset is preserved.

## Power BI exports
The script exports three CSV datasets into data/processed/:

| File | Description |
|---|---|
| `patent_records.csv` | Original records with derived years and registration intervals |
| `ipc_codes.csv` | Unique patent–IPC classification assignments |
| `registration_intervals_summary.csv` | Summary statistics by record type |

The export validation confirms 34,223 patent records, 131,929 IPC assignments and 10,848 eligible interval observations.

Record-level intervals allow Power BI to calculate dynamically filtered means and medians. The precomputed summary provides fixed reference statistics.

## Reproducing the Python workflow
Requirements: Python 3.13, MariaDB with the patendiamet_analytics database imported, and the packages listed in requirements.txt.

From the project directory in Git Bash:

python -m venv .venv
source .venv/Scripts/activate
python -m pip install -r requirements.txt
python python/extract_transform.py

The script prompts for the local MariaDB password without storing it in the source code.

The CSV files are regenerated automatically. The pipeline is read-only with respect to the source database.

Data limitations: The outputs describe the public Patendiamet database snapshot from 14 October 2026, not necessarily all applications received or all registration event. Database record types, administrative statuses and data fields require context-specific interpretation.

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
