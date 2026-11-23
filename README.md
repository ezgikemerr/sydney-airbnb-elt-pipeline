# Sydney Airbnb ELT Pipeline & Data Warehouse

**Apache Airflow | Google Cloud Composer | Google Cloud Storage | PostgreSQL | dbt Cloud | SQL**

## Project Overview

This project builds an end-to-end **Extract, Load, Transform (ELT)** pipeline to integrate Sydney Airbnb listing data with Australian Census and geographic reference datasets. The solution uses a **Bronze–Silver–Gold Medallion Architecture** in PostgreSQL, with Apache Airflow for ingestion and dbt for transformations, historical tracking, and analytical modelling.

The resulting data warehouse supports regional revenue comparisons, property and host analysis, demographic insights, and estimated mortgage coverage assessments.

## Dependencies

- Python 3.x
- Apache Airflow (Google Cloud Composer)
- PostgreSQL (Google Cloud SQL)
- dbt Cloud
- Google Cloud Storage
- DBeaver (optional, for SQL queries and validation)

### Python Libraries
- apache-airflow-providers-postgres
- google-cloud-storage
- psycopg2

## Setup Instructions

### 1. Clone the Repository

```text
git clone https://github.com/ezgikemerr/sydney-airbnb-elt-pipeline.git
cd sydney-airbnb-elt-pipeline
```

1. **Download the data** using the links in [Dataset Overview](#dataset-overview) and upload the CSVs to the Composer bucket's `data/` directory.
2. **Provision PostgreSQL** on Cloud SQL and run `part_1.sql` to create the Bronze schema and raw tables.
3. **Configure Airflow** with the PostgreSQL connection (`postgres_bde`), appropriate GCP permissions, and the project's DAG. Update environment-specific bucket/database settings before running.
4. **Configure dbt Cloud** to connect to PostgreSQL and deploy the project's dbt models, snapshots and macros.
5. **Run the initial load** for May 2020, including the static Census/LGA files. For subsequent months, trigger the DAG chronologically and run the Silver → snapshot → Gold commands shown above after each load.
6. **Validate the warehouse** with SQL row-count and dimension-identifier checks. Run `part_4.sql` for the five business analyses.

## Dataset

The project uses **16 CSV files**:

| Source | Coverage | Files |
| --- | --- | ---: |
| Sydney Airbnb listings | Monthly extracts, May 2020–April 2021 | 12 |
| Australian Census 2016 | G01: demographic characteristics; G02: medians and averages | 2 |
| NSW geographic reference data | LGA codes and LGA–suburb mapping | 2 |
| **Total** | | **16** |

## Technology Stack

- **Google Cloud Storage / Cloud Composer bucket:** Source CSV storage
- **Apache Airflow (Cloud Composer):** Monthly ingestion and task orchestration
- **Cloud SQL for PostgreSQL:** Data warehouse and analytical SQL
- **dbt Cloud:** Data cleaning, modelling, SCD Type 2 snapshots, and datamarts
- **DBeaver:** Database inspection, validation, and ad-hoc analysis

## Pipeline Architecture

```text
Source CSVs (Airbnb + Census + LGA mappings)
                    |
                    v
          Google Cloud Storage
                    |
                    v
           Apache Airflow DAG
                    |
                    v
       PostgreSQL / Bronze (raw)
                    |
                    v
       dbt / Silver (staging + entities)
                    |
                    +--> SCD Type 2 snapshots
                    |
                    v
       dbt / Gold (dimensions + fact)
                    |
                    v
         Analytical datamart views
                    |
                    v
            Ad-hoc SQL analysis
```

## Data Pipeline Implementation

### 1. Bronze — Raw Ingestion

An Airflow DAG loads the initial May 2020 Airbnb extract and four **static reference files** (Census G01/G02 and LGA mappings) into PostgreSQL Bronze tables. The remaining 11 Airbnb files are loaded chronologically by manually triggering the same DAG with a month parameter. Before each insert, the loader replaces existing records matching incoming `scraped_date` values to reduce the risk of duplicate loads.

### 2. Silver — Cleaning and Entity Preparation

dbt staging and intermediate models standardise dates, suburb/LGA names and Census identifiers, then prepare host, listing, location and property entities. The Silver layer also reconciles Census LGA codes with the geographical mapping used by Airbnb listings.

### 3. SCD Type 2 — Historical Tracking

Two dbt timestamp snapshots, **`snap_hosts`** and **`snap_listings`**, preserve changes in host and listing attributes. Historical identifiers and validity periods support time-aware joins from the fact table to the relevant dimension records.

### 4. Gold — Dimensional Warehouse and Datamarts

| Model type | Models |
|---|---|
| Dimensions | `dim_host`, `dim_listing`, `dim_location`, `dim_property` |
| Fact | `fact_listings` |
| Census references | `ref_census_g01`, `ref_census_g02` |
| Analytical datamarts | `dm_listing_neighbourhood`, `dm_property_type`, `dm_host_neighbourhood` |

### Monthly Execution Sequence

After each Airflow monthly ingestion, the dbt transformations were run **manually** in this order:

```bash
dbt run --select path:models/silver
dbt snapshot
dbt run --select path:models/gold
```

*The Airflow DAG handles ingestion; it does not automatically trigger the dbt Cloud commands in this implementation.*

## Data Validation

| Validation | Result |
| --- | ---: |
| Initial May 2020 Airbnb records | 37,562 |
| Final Bronze Airbnb records | 412,122 |
| Final Gold fact records | 412,122 |
| Missing listing SCD IDs | 0 |
| Missing host SCD IDs | 0 |
| Missing property IDs | 0 |

## Business Analysis

Five ad-hoc PostgreSQL analyses explored:

1. **Regional performance and demographics:** Top and bottom three LGAs by estimated revenue per active listing.
2. **Median age and revenue:** Pearson correlation across 29 listing neighbourhoods (**r = 0.6834**).
3. **Best listing configurations:** Property type, room type, and guest capacity in the top five neighbourhoods.
4. **Multi-listing hosts:** **76.82%** operated within one LGA; **23.18%** across multiple LGAs.
5. **Mortgage coverage:** Northern Beaches had the highest share of single-listing hosts meeting the annualised median mortgage benchmark (**57.26%**).

Revenue figures are **estimates**, not verified earnings or net profit. The demographic correlation does not imply causation.

## Repository Contents

```text
.
├── README.md
├── part_1.sql                        # Bronze schema and raw tables
├── bde_at3_combined_raw_load_fixed.py # Airflow ingestion DAG
├── part_4.sql                        # Ad-hoc business analysis
└── dbt-cloud-70506183167696-bde/
    ├── dbt_project.yml
    ├── macros/
    │   └── generate_schema_name.sql
    ├── models/
    │   ├── silver/                   # Staging and intermediate models
    │   └── gold/                     # Dimensions, fact, references, datamarts
    └── snapshots/                    # Host and listing SCD2 snapshots
```

The project submission also includes a separate handover report with implementation details and validation evidence.

## Key Takeaway

The project demonstrates how cloud-based ingestion, dbt transformations, historical dimension management, and SQL analytics can be combined into a reproducible data engineering workflow. Future enhancements could automate dbt execution after Airflow ingestion and add more extensive data quality tests and monitoring.
