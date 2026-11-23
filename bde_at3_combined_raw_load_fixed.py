import os
import logging
import pandas as pd
from datetime import datetime, timedelta
from psycopg2.extras import execute_values

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

dag_default_args = {
    "owner": "BDE_AT3",
    "start_date": datetime(2026, 10, 1),
    "email": [],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "depends_on_past": False,
    "wait_for_downstream": False,
}

dag = DAG(
    dag_id="bde_at3_combined_raw_load",
    default_args=dag_default_args,
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    params={"month": "05_2020"},
)

AIRFLOW_DATA = "/home/airflow/gcs/data"

VALID_MONTHS = [
    "05_2020", "06_2020", "07_2020", "08_2020",
    "09_2020", "10_2020", "11_2020", "12_2020",
    "01_2021", "02_2021", "03_2021", "04_2021",
]

CENSUS_G01_FILE = os.path.join(AIRFLOW_DATA, "2016Census_G01_NSW_LGA.csv")
CENSUS_G02_FILE = os.path.join(AIRFLOW_DATA, "2016Census_G02_NSW_LGA.csv")
LGA_CODE_FILE = os.path.join(AIRFLOW_DATA, "NSW_LGA_CODE.csv")
LGA_SUBURB_FILE = os.path.join(AIRFLOW_DATA, "NSW_LGA_SUBURB.csv")


def load_csv_to_postgres(file_path, table_name, replace_table=False, replace_scraped_dates=False):
    logging.info("Starting load for file: %s", file_path)

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    df = pd.read_csv(file_path)

    if len(df) == 0:
        raise ValueError(f"CSV file is empty: {file_path}")

    df.columns = [str(column).strip().lower() for column in df.columns]
    df = df.astype(object).where(pd.notnull(df), None)

    postgres_hook = PostgresHook(postgres_conn_id="postgres_bde")
    conn = postgres_hook.get_conn()

    try:
        with conn.cursor() as cursor:
            if replace_table:
                cursor.execute(f"DELETE FROM {table_name}")

            if replace_scraped_dates:
                if "scraped_date" not in df.columns:
                    raise ValueError("scraped_date column not found in listings CSV")

                scraped_dates = [
                    str(value).strip()
                    for value in df["scraped_date"].dropna().unique()
                ]

                if scraped_dates:
                    logging.info(
                        "Replacing existing scraped_date values in %s: %s",
                        table_name,
                        scraped_dates,
                    )
                    cursor.execute(
                        f"DELETE FROM {table_name} WHERE scraped_date = ANY(%s)",
                        (scraped_dates,),
                    )

            columns = list(df.columns)
            values = df.to_dict("split")["data"]

            quoted_columns = ", ".join(
                '"' + str(column).replace('"', '""') + '"'
                for column in columns
            )

            insert_sql = f'''
                INSERT INTO {table_name} ({quoted_columns})
                VALUES %s
            '''

            execute_values(cursor, insert_sql, values, page_size=1000)

        conn.commit()
        logging.info("SUCCESS: Loaded %s rows from %s into %s", len(df), file_path, table_name)

    except Exception:
        conn.rollback()
        logging.exception("ERROR while loading %s into %s", file_path, table_name)
        raise
    finally:
        conn.close()


def load_listings_func(**context):
    month = context["params"]["month"]

    if month not in VALID_MONTHS:
        raise ValueError(f"Invalid month: {month}. Valid months are: {VALID_MONTHS}")

    listings_file = os.path.join(AIRFLOW_DATA, f"{month}.csv")

    load_csv_to_postgres(
        listings_file,
        "bronze.raw_listings",
        replace_scraped_dates=True,
    )


def load_reference_data_func(**context):
    month = context["params"]["month"]

    if month != "05_2020":
        logging.info("Month is %s. Reference data load is skipped.", month)
        return

    load_csv_to_postgres(
        CENSUS_G01_FILE, "bronze.raw_census_g01", replace_table=True
    )
    load_csv_to_postgres(
        CENSUS_G02_FILE, "bronze.raw_census_g02", replace_table=True
    )
    load_csv_to_postgres(
        LGA_CODE_FILE, "bronze.raw_lga_code", replace_table=True
    )
    load_csv_to_postgres(
        LGA_SUBURB_FILE, "bronze.raw_lga_suburb", replace_table=True
    )


load_listings_task = PythonOperator(
    task_id="load_monthly_airbnb_listings",
    python_callable=load_listings_func,
    dag=dag,
)

load_reference_data_task = PythonOperator(
    task_id="load_initial_reference_data",
    python_callable=load_reference_data_func,
    dag=dag,
)

load_reference_data_task >> load_listings_task
