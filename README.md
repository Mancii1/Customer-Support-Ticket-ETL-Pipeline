# Customer Support Ticket ETL Pipeline

![Python](https://img.shields.io/badge/Python-3.12%2B-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-green)
![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-yellow)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

A complete end‑to‑end ETL pipeline that ingests raw customer support ticket data, transforms it, loads it into a normalised PostgreSQL database, and presents key operational and business metrics through an interactive Power BI dashboard. Built to simulate a real‑world BPO (Business Process Outsourcing) reporting system.

---

## 📖 Project Overview

**Goal:**  
To build a robust, production‑grade data pipeline that turns a messy CSV export from a hypothetical support ticketing system into actionable insights. The project covers every layer of the modern data stack: Python scripting, data cleaning & transformation, database design, SQL querying, and BI reporting.

**Key Outcomes:**  
- An automated ETL pipeline written in Python.
- A normalized PostgreSQL database with 3 tables.
- A set of reusable SQL analysis queries.
- A dual‑page Power BI dashboard (Operations & Business views) backed by DAX measures.
- Full documentation (this README) and version control via Git/GitHub.

---

## 🧱 Tech Stack

| Category | Tools / Libraries |
|----------|-------------------|
| **Language** | Python 3.10+ |
| **Data Processing** | Pandas, NumPy |
| **Database** | PostgreSQL, pgAdmin |
| **Connection** | SQLAlchemy, psycopg2‑binary |
| **Configuration** | python‑dotenv |
| **BI & Analytics** | Power BI Desktop (DAX measures) |
| **Version Control** | Git, GitHub |
| **IDE** | VS Code |

---

## 🚀 ETL Pipeline Architecture

CSV Dataset
↓
[Extract] (Python / Pandas)
↓
[Transform] (Cleaning, date parsing, feature engineering)
↓
[Load] (PostgreSQL flat table)
↓
[SQL Normalisation] (customers, products, tickets)
↓
[Analysis Queries] (KPI calculations)
↓
[Power BI Dashboard] (DAX measures, interactive visuals)

---

## 🧪 Dataset

The dataset contains **8,469** support ticket records with columns such as:

- Ticket ID, Customer details (name, email, age, gender)
- Product purchased, Date of purchase
- Ticket type, subject, description, status, priority, channel
- `First Response Time` (timestamp) and `Time to Resolution` (timestamp)
- Customer Satisfaction Rating

**Note:** Despite their names, both `First Response Time` and `Time to Resolution` were **timestamp fields** in the raw data, representing the moment of first reply and closure. This discovery drove a major adaptation in the transform logic (see Challenges section).

---

## ⚙️ ETL Pipeline Details

### 1. Extract (`extract.py`)
- Reads the CSV using Pandas with error handling.
- Prints row count for logging.

### 2. Transform (`transform.py`)
This is the heart of the pipeline. Key steps:
- Remove duplicate rows.
- Standardise column names (lowercase, underscores).
- **Parse datetime columns**: Convert `date_of_purchase`, `first_response_time`, `time_to_resolution` from string to proper datetime objects.
- **Compute true durations**: Subtract `date_of_purchase` from the two timestamps to get `first_response_duration` and `resolution_duration`, then rename them back to `first_response_time` and `time_to_resolution` (now as timedelta values).
- Drop rows missing critical IDs.
- **Feature Engineering**:
  - `is_sla_breached`: True if resolution duration exceeds 48 hours.
  - `response_speed_category`: “fast” (<1h), “medium” (1‑6h), “slow” (>6h).
- Output cleaned DataFrame (8,469 rows).

### 3. Load (`load.py`)
- Pushes the transformed DataFrame into a PostgreSQL table (`tickets_flat`) via SQLAlchemy.
- The `timedelta` columns are stored as bigint (nanoseconds) because of driver limitations – this is handled later during normalisation.

### 4. Normalisation (SQL scripts)
- `create_tables.sql`: Defines `customers`, `products`, and `tickets` tables with primary/foreign keys.
- `insert_data.sql`: Migrates data from `tickets_flat` into the normalised schema.  
  - Uses `DISTINCT ON` to deduplicate customers by email.  
  - Converts nanosecond integers back to proper PostgreSQL `INTERVAL` using `(value::numeric / 1000000000.0) * INTERVAL '1 second'`.
- After migration, a cleaning step removes any residual `NaT` sentinel values (`-9223372036854775808`) by setting them to `NULL`.

---

## 📊 Analysis Queries

The file `sql/analysis_queries.sql` contains 10+ queries that answer critical business questions:

| Metric | Query |
|--------|-------|
| Total, Open, Closed Tickets | Simple COUNT with filters |
| Tickets by Type / Priority / Channel | GROUP BY aggregations |
| Tickets Created Over Time | COUNT grouped by date |
| Average Resolution Time (hours) | `EXTRACT(EPOCH FROM interval)/3600` |
| Average Satisfaction Rating | `AVG()` |
| SLA Breaches (48‑hour target) | Filter `resolution > INTERVAL '48 hours'` |
| 24‑hour Internal Target Breaches | Same with 24 hours |
| Breach Percentage | Subquery for total |

All queries are self‑contained and can be executed directly in pgAdmin or loaded into Power BI.

---

## 📈 Power BI Dashboard

Two report pages serve different stakeholders:

### **Operations Dashboard**
- **Cards**: Total, Open, Closed tickets; Avg First Response & Resolution times; SLA Breaches (48h & 24h).
- **Line Chart**: Ticket volume over time.
- **Bar Charts**: Tickets by Priority, Channel.
- **Slicers**: Status, Priority.

### **Business Dashboard**
- **Cards**: Average Satisfaction, SLA Breach %, Total Tickets.
- **Bar Chart**: Tickets by Product.
- **Pie Chart**: Tickets by Type.
- **Table**: Top products with satisfaction scores.
- **Line Chart**: Satisfaction trend over time.
- **Slicers**: Product, Customer Gender.

All visuals are powered by **DAX measures** created on the `tickets` fact table, which connects to `customers` and `products` dimensions in a star schema. This enables cross‑filtering and drill‑down without duplicating data.

---

## 🧠 Challenges & Solutions

### 1. `pd.to_timedelta` Failed on Raw Data
**Problem:**  
The transformation step threw a `ValueError` because the columns `first_response_time` and `time_to_resolution` were expected to be duration strings (like “2 hours”), but they were actually **timestamps** (e.g., “6/1/2023 12:15”).

**Solution:**  
Examined the CSV directly, discovered the mismatch, and rewrote the transform logic to parse them as datetimes, then calculate durations by subtracting `date_of_purchase`. This not only fixed the error but produced accurate performance metrics.

---

### 2. Negative / NaN Sentinel Values in Database
**Problem:**  
After loading, all `time_to_resolution` values became the monstrous negative integer `-9223372036854775808` (the Pandas `NaT` sentinel). Any unparseable date or missing value turned into this. Averaging such values produced a meaningless `-2.5 million hours`.

**Solution:**  
- Diagnosed with diagnostic SQL: counted rows with `INTERVAL '-100000 days'`.  
- Updated the table to set sentinel values to `NULL`.  
- Only valid positive durations remained, giving a realistic average (~21 hours).  
- Documented the cleaning step as a data quality fix.

---

### 3. Duplicate Customer Emails Violated Unique Constraint
**Problem:**  
The `customers` table has a `UNIQUE` constraint on `customer_email`. The flat source contained the same email with slightly different names/ages, causing a `duplicate key value` error during `INSERT`.

**Solution:**  
Used PostgreSQL’s `DISTINCT ON (customer_email)` to deduplicate, keeping one row per email during the migration. This preserved referential integrity while maintaining correct ticket‑customer links.

---

### 4. Interval Conversion Syntax Errors
**Problem:**  
Initially tried `(value * INTERVAL '1 nanosecond')::INTERVAL`, but PostgreSQL rejected the unknown unit “nanosecond”. Then encountered invisible Unicode characters causing cryptic `syntax error at or near "FROM"`.

**Solution:**  
- Replaced with arithmetic: `(value::numeric / 1000000000.0) * INTERVAL '1 second'`, which is both valid and precise.  
- Typed the query manually to eliminate hidden characters, then saved the clean copy in the project.

---

### 5. Power BI Measure Visibility
**Problem:**  
After creating a new measure, it “disappeared” – not showing in the fields list.

**Solution:**  
Realised the measure was being created in a different table (the one last clicked). Located it, dragged it back to the `tickets` table, and learned to select the fact table explicitly before creating measures.

---

## 💡 Lessons Learned

- **Always inspect raw data before building transformations** – column names can be misleading.
- **Use `errors='coerce'` and diagnostic queries** to surface data quality issues early.
- **Normalise data during load, not after** – planning the migration from flat to star schema requires careful deduplication and type casting.
- **SLA thresholds are business‑specific** – a good engineer keeps them configurable and explains why 0 breaches can be a valid finding.
- **Power BI star schema + DAX is highly reusable** – the same measures served two completely different dashboard perspectives.
