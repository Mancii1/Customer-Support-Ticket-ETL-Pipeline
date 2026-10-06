# Customer Support Ticket ETL Pipeline (PostgreSQL + Snowflake + dbt)

![Python](https://img.shields.io/badge/Python-3.10-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-green)
![Snowflake](https://img.shields.io/badge/Snowflake-Cloud-29B5E8)
![dbt](https://img.shields.io/badge/dbt-1.7-orange)
![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-yellow)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

An end-to-end data pipeline that ingests raw customer support ticket data, transforms it into a normalized star schema, and surfaces operational and business insights through an interactive Power BI dashboard.

This project demonstrates **two complementary paradigms** in a single repository:

1. **Classic ETL** — Python + Pandas + PostgreSQL (raw → transform → load).
2. **Modern ELT** — Python extraction + Snowflake + dbt (load raw → transform in warehouse).

Both implementations share the same source data and the same downstream dashboard, making it easy to compare approaches.

---

## 📖 Project Overview

**Goal:**
Build a production-ready pipeline that turns a messy CSV export from a hypothetical support ticketing system into clean, queryable datasets used for BPO reporting.

**Target Roles:**
Junior Database Engineer · Data Engineer · Analytics Engineer · Data Analyst

**Key Outcomes:**
- Two complete, working implementations of the same pipeline.
- A normalized star schema with fact and dimension tables.
- A full suite of analysis SQL queries and dbt tests.
- An interactive Power BI dashboard (Operations & Business pages).
- Full documentation and version control.

---

## 🧱 Tech Stack

| Layer | Classic ETL | Modern ELT |
|-------|-------------|------------|
| Language | Python 3.10 | Python 3.10 |
| Processing | Pandas, NumPy | Pandas (extract only) |
| Warehouse | PostgreSQL 16 | Snowflake (trial) |
| Transform | Pandas scripts + SQL | dbt (staging → intermediate → marts) |
| Testing | Manual SQL checks | dbt tests (unique, not_null, accepted_values, custom) |
| Lineage | — | dbt docs (auto-generated) |
| BI | Power BI (DAX) | Power BI (DAX) |
| Version Control | Git / GitHub | Git / GitHub |

---

## 🗂️ Project Structure

```
customer-support-etl/
│
├── data/
│     └── customer_support_tickets.csv     # 8,469 raw ticket records
│
├── scripts/                               # Python ETL (loads to Postgres or Snowflake)
│     ├── config.py                        # DB engines for both platforms
│     ├── extract.py                       # CSV reader
│     ├── transform.py                     # (classic path only)
│     ├── load.py                          # (classic path → PostgreSQL)
│     ├── load_snowflake.py                # (modern path → Snowflake RAW)
│     └── main.py                          # Pipeline entry point
│
├── sql/                                   # PostgreSQL scripts (classic path)
│     ├── create_tables.sql
│     ├── insert_data.sql
│     └── analysis_queries.sql
│
├── dbt_project/                           # Modern ELT (Snowflake)
│     ├── dbt_project.yml
│     ├── profiles.yml
│     ├── models/
│     │     ├── staging/
│     │     │     ├── stg_tickets.sql
│     │     │     └── schema.yml
│     │     ├── intermediate/
│     │     │     └── int_tickets_enriched.sql
│     │     └── marts/
│     │           ├── dim_customers.sql
│     │           ├── dim_products.sql
│     │           ├── fct_tickets.sql
│     │           └── schema.yml
│     ├── tests/
│     │     └── assert_no_negative_duration.sql
│     └── macros/
│
├── dashboard/
│     └── customer-support-dashboard.pbix
│
├── screenshots/
│     ├── operations_dashboard.png
│     └── business_dashboard.png
│
├── requirements.txt
├── .env
├── .gitignore
└── README.md
```

---

## 🧪 Dataset

The source CSV contains **8,469 rows** with the following fields:

| Column | Description |
|--------|-------------|
| Ticket ID | Primary identifier |
| Customer Name / Email / Age / Gender | Customer attributes |
| Product Purchased | Product associated with the ticket |
| Date of Purchase | When the product was bought |
| Ticket Type / Subject / Description | Categorisation of the issue |
| Ticket Status / Priority / Channel | Operational attributes |
| Resolution | Free-text resolution notes |
| First Response Time | **Timestamp** of first agent reply |
| Time to Resolution | **Timestamp** of ticket closure |
| Customer Satisfaction Rating | 1–5 score |

> ⚠️ **Critical data discovery:** Despite their names, `First Response Time` and `Time to Resolution` are **timestamps**, not durations. This drove a major adaptation in both pipelines — durations are computed by subtracting `Date of Purchase`.

---

## 🏗️ Architecture

### Classic ETL (PostgreSQL)

```
CSV  →  Python Extract  →  Python Transform  →  PostgreSQL (tickets_flat)
                                                      ↓
                                        SQL Normalisation (customers,
                                        products, tickets)
                                                      ↓
                                             Analysis Queries
                                                      ↓
                                               Power BI
```

### Modern ELT (Snowflake + dbt)

```
CSV  →  Python Extract  →  Snowflake RAW.tickets_raw
                                    ↓
                          dbt: stg_tickets (staging)
                                    ↓
                          dbt: int_tickets_enriched (intermediate)
                                    ↓
                          dbt: dim_customers, dim_products, fct_tickets (marts)
                                    ↓
                            Snowflake ANALYTICS schema
                                    ↓
                               Power BI
```

---

## 🐍 Classic ETL Details (PostgreSQL)

### Extract
`extract.py` reads the CSV into a Pandas DataFrame with basic error handling.

### Transform
`transform.py`:
- Removes duplicates and standardises column names (lowercase, underscores).
- Parses `date_of_purchase`, `first_response_time`, and `time_to_resolution` as **datetimes**.
- Computes `first_response_duration` and `resolution_duration` as **timedeltas**.
- Adds `is_sla_breached` (resolution > 48 hours) and `response_speed_category` (fast / medium / slow).

### Load
`load.py` writes the transformed DataFrame to `tickets_flat` in PostgreSQL.

### Normalisation (SQL)
- `create_tables.sql` defines the `customers`, `products`, and `tickets` tables.
- `insert_data.sql` migrates data from `tickets_flat`:
  - Deduplicates customers with `DISTINCT ON (customer_email)`.
  - Converts Pandas nanosecond bigints to Postgres `INTERVAL` with `(value / 1e9) * INTERVAL '1 second'`.
  - Cleans NaT sentinels (`-9223372036854775808` nanoseconds) by setting them to `NULL`.

### Analysis
`analysis_queries.sql` contains 10+ queries covering total/open/closed tickets, tickets by type/priority/channel, average resolution time, average satisfaction, SLA breaches (48h and 24h targets), and a drill-down detail query.

---

## ❄️ Modern ELT Details (Snowflake + dbt)

### Snowflake Setup

```sql
CREATE WAREHOUSE support_wh WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;

CREATE DATABASE support_db;
CREATE SCHEMA support_db.raw;         -- landing zone for Python loads
CREATE SCHEMA support_db.staging;     -- dbt staging models
CREATE SCHEMA support_db.analytics;   -- dbt marts
```

### Python Load

`load_snowflake.py` writes the raw CSV into `support_db.raw.tickets_raw` using SQLAlchemy with the Snowflake connector.

### dbt Models

| Layer | Model | Purpose |
|-------|-------|---------|
| Staging | `stg_tickets` | Casts types, filters invalid emails |
| Intermediate | `int_tickets_enriched` | Computes durations, SLA flag, response speed |
| Marts | `dim_customers` | Unique customers |
| Marts | `dim_products` | Unique products |
| Marts | `fct_tickets` | Fact table joined to dimensions |

### dbt Tests

- `unique` and `not_null` on `ticket_id`
- `not_null` on `customer_email`
- `accepted_values` on `ticket_status`
- Custom test `assert_no_negative_duration` ensures no negative durations exist

### dbt Docs

Running `dbt docs generate && dbt docs serve` produces an interactive lineage graph showing the full path from `raw.tickets_raw` to `analytics.fct_tickets` — a strong interview demonstration.

---

## 📊 Power BI Dashboard

The dashboard is identical regardless of which backend is used (Postgres or Snowflake), because both produce the same star schema with the same column names.

### Page 1 — Operations Dashboard
- **Cards:** Total Tickets, Open, Closed, Avg First Response (hrs), Avg Resolution (hrs), SLA Breaches (48h), Breach %, Internal Target Breaches (24h).
- **Line chart:** Ticket volume over time.
- **Bar charts:** Tickets by Priority and by Channel.
- **Slicers:** Status, Priority.

### Page 2 — Business Dashboard
- **Cards:** Avg Satisfaction, SLA Breach %, Total Tickets.
- **Pie chart:** Tickets by Type.
- **Bar chart:** Tickets by Product.
- **Table:** Top products with ticket count and satisfaction.
- **Line chart:** Satisfaction trend over time.
- **Slicers:** Product, Customer Gender.

### Key DAX Measures

```dax
Total Tickets = COUNTROWS(tickets)

Open Tickets =
CALCULATE(COUNTROWS(tickets), tickets[ticket_status] = "Open")

Closed Tickets =
CALCULATE(COUNTROWS(tickets), tickets[ticket_status] = "Closed")

Avg Resolution Hours =
AVERAGEX(
    FILTER(tickets, NOT(ISBLANK(tickets[time_to_resolution]))),
    tickets[time_to_resolution] * 24
)

Avg Satisfaction = AVERAGE(tickets[customer_satisfaction_rating])

SLA Breaches =
COUNTROWS(FILTER(tickets, tickets[time_to_resolution] * 24 > 48))

SLA Breach % = DIVIDE([SLA Breaches], [Total Tickets], 0)

24h Breaches =
COUNTROWS(FILTER(tickets, tickets[time_to_resolution] * 24 > 24))
```

---

## 🧠 Challenges & Solutions

### 1. Column Names Were Misleading — Timestamps vs. Durations
**Problem:** `pd.to_timedelta` threw `ValueError: only leading negative signs are allowed` because `First Response Time` and `Time to Resolution` were actually timestamps.
**Solution:** Parsed them as datetimes, subtracted `date_of_purchase`, and produced true durations. This discovery reshaped the entire transform logic.

### 2. Pandas NaT Sentinel in PostgreSQL
**Problem:** NaT values were stored as `-9223372036854775808` nanoseconds, resulting in meaningless negative averages (`-2,562,047 hours`).
**Solution:** Added a cleaning `UPDATE` to set values below `-100000 days` to `NULL`.

### 3. Duplicate Customer Emails Broke the UNIQUE Constraint
**Problem:** The same email appeared with different names/ages.
**Solution:** Used PostgreSQL `DISTINCT ON (customer_email)` to keep one row per email.

### 4. Interval Conversion Syntax Error
**Problem:** `INTERVAL '1 nanosecond'` is not a valid Postgres unit; and hidden Unicode characters produced `syntax error at or near "FROM"`.
**Solution:** Replaced with `(value::numeric / 1000000000.0) * INTERVAL '1 second'` and typed the query manually to remove hidden characters.

### 5. dbt Source Reference and Schema Mapping
**Problem:** `dbt run` initially failed because the `raw` schema wasn’t declared as a source.
**Solution:** Added a `sources:` block in `staging/schema.yml` and pointed it at `support_db.raw.tickets_raw`.

### 6. Snowflake Trial Role Permissions
**Problem:** dbt couldn’t create tables in `analytics`.
**Solution:** Granted `ALL PRIVILEGES` on the database and future schemas to `dbt_role`, then set it as the dbt profile role.

---

## 🧪 How to Run

### Prerequisites
- Python 3.10+
- PostgreSQL (for the classic path)
- Snowflake trial account (for the modern path)
- Power BI Desktop
- Git

### 1. Clone and install
```bash
git clone https://github.com/YOUR_USERNAME/customer-support-etl.git
cd customer-support-etl
python -m venv venv
venv\Scripts\activate           # Windows
pip install -r requirements.txt
```

### 2. Configure `.env`
```env
# PostgreSQL (classic path)
DB_USER=postgres
DB_PASSWORD=yourpassword
DB_HOST=localhost
DB_PORT=5432
DB_NAME=support_db

# Snowflake (modern path)
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_WAREHOUSE=support_wh
SNOWFLAKE_DATABASE=support_db
SNOWFLAKE_SCHEMA=raw
SNOWFLAKE_ROLE=dbt_role
```

### 3. Run the classic pipeline
```bash
python scripts/main.py
```
Then in pgAdmin, execute `sql/create_tables.sql`, `sql/insert_data.sql`, and `sql/analysis_queries.sql`.

### 4. Run the modern pipeline
```bash
python scripts/main.py                     # loads RAW.tickets_raw into Snowflake
cd dbt_project
dbt debug
dbt run
dbt test
dbt docs generate && dbt docs serve
```

### 5. Open the Power BI dashboard
Open `dashboard/customer-support-dashboard.pbix` and refresh the connection (Postgres or Snowflake).

---

## 📸 Screenshots

### Operations Dashboard
![Operations Dashboard](screenshots/operations_dashboard.png)

### Business Dashboard
![Business Dashboard](screenshots/business_dashboard.png)

---

## 🏆 Why This Project Matters

This project demonstrates the full toolkit expected of a modern data professional:

- **Two transformation paradigms** — classic ETL in Python and modern ELT with dbt.
- **Warehouse design** — normalised star schema with fact and dimension tables.
- **Cloud data warehouse** — Snowflake warehouse, schemas, roles, and grants.
- **Data quality as code** — dbt tests for uniqueness, nullability, and business rules.
- **Documentation as code** — auto-generated dbt lineage and column descriptions.
- **Reporting** — Power BI dashboard with reusable DAX measures.
- **Real debugging experience** — timestamps mislabeled as durations, NaT sentinels, Unicode corruption, foreign key dependencies.

---

**Built with Python, PostgreSQL, Snowflake, dbt, and a lot of debugging.** 🚀
