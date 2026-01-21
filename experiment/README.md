# E-Commerce Analytics Platform

A production-ready data transformation pipeline built with dbt (data build tool) for e-commerce analytics. This project demonstrates modern data engineering best practices including dimensional modeling, historical change tracking, automated testing, and business intelligence reporting.

![dbt](https://img.shields.io/badge/dbt-1.10+-orange.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)
![Tests](https://img.shields.io/badge/tests-39%20passing-success.svg)

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Data Models](#data-models)
- [Usage Guide](#usage-guide)
- [Testing](#testing)
- [Advanced Features](#advanced-features)
- [Development](#development)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This project implements a complete ETL (Extract, Transform, Load) pipeline for an e-commerce platform, transforming raw operational data into analytics-ready dimensional models. It includes customer segmentation, product performance analytics, order metrics, and advanced features like historical tracking and RFM analysis.

### Key Capabilities

- **Dimensional Data Warehouse** - Star schema with fact and dimension tables
- **Data Quality Testing** - 39 automated tests ensuring data integrity
- **Historical Tracking** - Type 2 SCD for price and customer changes
- **Business Intelligence** - Pre-built analyses for common business questions
- **Reusable Components** - Custom macros for consistent calculations

### Technology Stack

- **Transformation:** dbt 1.10+
- **Database:** PostgreSQL 15
- **Orchestration:** Docker Compose
- **Language:** SQL, Jinja2

---

## 🏗️ Architecture

### Data Flow

```
┌─────────────────┐
│  Raw Data       │  ← Source systems (CSV seeds for demo)
│  (PostgreSQL)   │
└────────┬────────┘
         │
         ├─── raw_customers
         ├─── raw_products
         ├─── raw_orders
         └─── raw_order_items
         │
         ▼
┌─────────────────┐
│  Staging Layer  │  ← Standardization, type casting, renaming
│  (Views)        │
└────────┬────────┘
         │
         ├─── stg_customers
         ├─── stg_products
         ├─── stg_orders
         └─── stg_order_items
         │
         ▼
┌─────────────────┐
│ Intermediate    │  ← Business logic, joins, calculations
│  (Views)        │
└────────┬────────┘
         │
         ├─── int_order_items_joined
         └─── int_customer_orders
         │
         ▼
┌─────────────────┐
│  Marts Layer    │  ← Analytics-ready dimensional models
│  (Tables)       │
└────────┬────────┘
         │
         ├─── fct_orders (Fact Table)
         ├─── dim_customers (Dimension)
         └─── dim_products (Dimension)
         │
         ▼
┌─────────────────┐
│  BI Tools /     │  ← Reporting, dashboards, analyses
│  Analyses       │
└─────────────────┘
```

### Database Schemas

```
my_warehouse
├── public               # Raw source data
├── analytics_staging    # Staging views
├── analytics_intermediate  # Intermediate views
├── analytics_marts      # Final dimension/fact tables
└── snapshots           # Historical change tracking
```

---

## ✨ Features

### Core Features

✅ **Dimensional Modeling**
- Star schema with 1 fact table and 2 dimension tables
- Optimized for analytical queries
- Denormalized for performance

✅ **Multi-Layer Architecture**
- Staging: Data standardization
- Intermediate: Business logic
- Marts: Analytics-ready outputs

✅ **Data Quality & Testing**
- 39 automated tests
- Referential integrity checks
- Custom business rule validation
- Source data validation

✅ **Historical Tracking**
- Type 2 SCD snapshots
- Price change history
- Customer address history
- Audit trail capabilities

### Advanced Features

✅ **Custom Macros**
- Profit margin calculations
- Date helpers
- Data quality validators
- Reusable SQL functions

✅ **Business Analyses**
- Monthly revenue analysis
- Customer cohort analysis
- Product performance reports
- RFM customer segmentation

✅ **Documentation**
- Auto-generated data lineage
- Column descriptions
- Test coverage reports
- Interactive DAG visualization

---

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Python 3.8+ with pip
- dbt-core and dbt-postgres

### Installation

1. **Clone and navigate to project:**
   ```bash
   cd /Users/macbook/Desktop/rnd/dbts/experiment
   ```

2. **Start PostgreSQL database:**
   ```bash
   cd ..
   docker-compose up -d db
   ```

   This will:
   - Start PostgreSQL on port 5432
   - Create raw tables automatically
   - Load sample e-commerce data (5 customers, 8 products, 7 orders)

3. **Set up dbt profile:**
   ```bash
   export DBT_PROFILES_DIR=/Users/macbook/Desktop/rnd/dbts/experiment
   ```

4. **Test connection:**
   ```bash
   cd experiment
   dbt debug
   ```

5. **Build the data warehouse:**
   ```bash
   dbt run
   ```

6. **Run tests:**
   ```bash
   dbt test
   ```

7. **View documentation:**
   ```bash
   dbt docs generate
   dbt docs serve
   ```
   Open http://localhost:8080 in your browser

### Verify Installation

```bash
# Check database contents
docker exec postgres_dw psql -U dbt_user -d my_warehouse -c "\
  SELECT customer_segment, COUNT(*)
  FROM analytics_marts.dim_customers
  GROUP BY customer_segment;"
```

Expected output:
```
customer_segment | count
-----------------|------
Regular          |   2
One-time         |   3
```

---

## 📁 Project Structure

```
experiment/
├── analyses/                    # Ad-hoc analyses and reports
│   ├── customer_cohort_analysis.sql
│   ├── customer_rfm_analysis.sql
│   ├── monthly_revenue_analysis.sql
│   └── product_performance_report.sql
│
├── macros/                      # Reusable SQL functions
│   ├── business_metrics.sql    # Profit, days_since, etc.
│   ├── date_helpers.sql        # Date manipulation
│   └── data_quality.sql        # Validation functions
│
├── models/                      # dbt models
│   ├── staging/                # Standardization layer
│   │   ├── sources.yml
│   │   ├── schema.yml
│   │   ├── stg_customers.sql
│   │   ├── stg_products.sql
│   │   ├── stg_orders.sql
│   │   └── stg_order_items.sql
│   │
│   ├── intermediate/           # Business logic layer
│   │   ├── int_order_items_joined.sql
│   │   └── int_customer_orders.sql
│   │
│   └── marts/                  # Analytics layer
│       ├── schema.yml
│       ├── fct_orders.sql
│       ├── dim_customers.sql
│       └── dim_products.sql
│
├── seeds/                       # CSV seed data
│   ├── raw_customers.csv
│   ├── raw_products.csv
│   ├── raw_orders.csv
│   └── raw_order_items.csv
│
├── snapshots/                   # Historical tracking
│   ├── customer_address_snapshot.sql
│   └── product_price_snapshot.sql
│
├── tests/                       # Custom data tests
│   ├── assert_no_negative_quantities.sql
│   ├── assert_order_totals_match.sql
│   ├── assert_positive_prices.sql
│   └── assert_valid_order_status.sql
│
├── dbt_project.yml             # Project configuration
├── profiles.yml                # Database connection
└── README.md                   # This file
```

---

## 📊 Data Models

### Fact Table

#### `fct_orders`
Order-level metrics and key performance indicators.

| Column | Type | Description |
|--------|------|-------------|
| order_id | INTEGER | Unique order identifier (PK) |
| customer_id | INTEGER | Reference to dim_customers |
| order_date | TIMESTAMP | When order was placed |
| status | VARCHAR | Order status |
| products_count | INTEGER | Number of distinct products |
| total_quantity | INTEGER | Total items ordered |
| order_revenue | NUMERIC | Total revenue |
| order_cost | NUMERIC | Total cost |
| order_profit | NUMERIC | Total profit |
| profit_margin_pct | NUMERIC | Profit margin percentage |

**Grain:** One row per order

### Dimension Tables

#### `dim_customers`
Customer master with lifetime metrics and segmentation.

| Column | Type | Description |
|--------|------|-------------|
| customer_id | INTEGER | Unique customer identifier (PK) |
| first_name | VARCHAR | Customer first name |
| last_name | VARCHAR | Customer last name |
| email | VARCHAR | Email address |
| phone | VARCHAR | Phone number |
| address | VARCHAR | Street address |
| city | VARCHAR | City |
| state | VARCHAR | State |
| zip_code | VARCHAR | ZIP code |
| country | VARCHAR | Country |
| lifetime_orders | INTEGER | Total orders placed |
| lifetime_revenue | NUMERIC | Total revenue generated |
| lifetime_profit | NUMERIC | Total profit generated |
| avg_order_value | NUMERIC | Average order value |
| first_order_date | TIMESTAMP | Date of first order |
| last_order_date | TIMESTAMP | Date of most recent order |
| customer_segment | VARCHAR | VIP, Loyal, Regular, One-time, New |

**Grain:** One row per customer (Type 1 SCD)

#### `dim_products`
Product master with sales performance metrics.

| Column | Type | Description |
|--------|------|-------------|
| product_id | INTEGER | Unique product identifier (PK) |
| product_name | VARCHAR | Product name |
| category | VARCHAR | Product category |
| subcategory | VARCHAR | Product subcategory |
| brand | VARCHAR | Brand name |
| current_price | NUMERIC | Current selling price |
| current_cost | NUMERIC | Current cost |
| stock_quantity | INTEGER | Current inventory level |
| times_ordered | INTEGER | Number of orders containing product |
| total_quantity_sold | INTEGER | Total units sold |
| total_revenue | NUMERIC | Total revenue generated |
| total_profit | NUMERIC | Total profit generated |
| avg_selling_price | NUMERIC | Average selling price |
| product_performance | VARCHAR | Best Seller, Popular, Moderate, Slow Moving, No Sales |

**Grain:** One row per product (Type 1 SCD, with Type 2 in snapshots)

---

## 💻 Usage Guide

### Common Commands

```bash
# Build all models
dbt run

# Build specific layer
dbt run --select staging
dbt run --select intermediate
dbt run --select marts

# Build specific model and dependencies
dbt run --select +dim_customers

# Build specific model and downstream
dbt run --select stg_customers+

# Full refresh (rebuild from scratch)
dbt run --full-refresh

# Test data quality
dbt test

# Test specific model
dbt test --select dim_customers

# Capture historical snapshots
dbt snapshot

# Compile analyses
dbt compile --select monthly_revenue_analysis

# Generate and view documentation
dbt docs generate
dbt docs serve
```

### Running Analyses

Analyses compile to SQL but don't create tables. To run them:

```bash
# 1. Compile the analysis
dbt compile --select customer_rfm_analysis

# 2. Run the compiled SQL
docker exec -i postgres_dw psql -U dbt_user -d my_warehouse \
  < target/compiled/experiment/analyses/customer_rfm_analysis.sql
```

### Querying Results

```bash
# Connect to database
docker exec -it postgres_dw psql -U dbt_user -d my_warehouse

# Example queries:
\dt analytics_marts.*                    # List tables
SELECT * FROM analytics_marts.dim_customers LIMIT 5;
SELECT * FROM analytics_marts.fct_orders ORDER BY order_date DESC LIMIT 10;

# Exit
\q
```

### Docker Management

```bash
# Start database
docker-compose up -d db

# Stop database
docker-compose down

# View logs
docker-compose logs -f db

# Reset database (deletes all data)
docker-compose down -v
docker-compose up -d db
# Wait for init scripts to run, then: dbt run
```

---

## 🧪 Testing

### Test Coverage

**39 total tests** across 4 categories:

1. **Generic Tests (35)**
   - Unique constraints
   - Not null checks
   - Referential integrity
   - Source data validation

2. **Custom Tests (4)**
   - Order totals match line items
   - No negative quantities
   - Positive prices
   - Valid order statuses

### Running Tests

```bash
# All tests
dbt test

# By model
dbt test --select dim_customers

# By type
dbt test --select test_type:unique
dbt test --select test_type:not_null
dbt test --select test_type:singular  # Custom tests

# By layer
dbt test --select staging
dbt test --select marts

# Source tests only
dbt test --select source:*
```

### Test Results

Current status: ✅ **39/39 passing**

```bash
dbt test
# Done. PASS=39 WARN=0 ERROR=0 SKIP=0 TOTAL=39
```

### Creating Custom Tests

Add SQL file to `tests/` directory:

```sql
-- tests/assert_customer_email_unique.sql
select
    email,
    count(*) as email_count
from {{ ref('dim_customers') }}
group by email
having count(*) > 1
```

Test fails if query returns any rows.

---

## 🔥 Advanced Features

### 1. Macros

Reusable SQL functions for consistent calculations.

**Example Usage:**

```sql
-- In any model
select
    order_id,
    revenue,
    cost,
    {{ calculate_profit_margin('revenue', 'cost') }} as margin_pct,
    {{ calculate_days_since('order_date') }} as days_old
from orders
```

**Available Macros:**
- `calculate_profit_margin(revenue, cost)` - Profit margin %
- `calculate_days_since(date)` - Days between date and today
- `cents_to_dollars(cents)` - Convert cents to dollars
- `get_date_parts(date)` - Extract year, month, day, etc.
- `get_fiscal_year(date, start_month)` - Calculate fiscal year
- `validate_email(email)` - Email format validation

### 2. Snapshots

Track historical changes (Type 2 SCD).

```bash
# Capture current state
dbt snapshot

# Query historical data
SELECT
    product_name,
    price,
    dbt_valid_from,
    dbt_valid_to
FROM snapshots.product_price_snapshot
WHERE product_id = 1
ORDER BY dbt_valid_from;
```

**Available Snapshots:**
- `product_price_snapshot` - Track price/cost changes
- `customer_address_snapshot` - Track address changes

### 3. Analyses

Pre-built business intelligence queries.

**Monthly Revenue Analysis:**
```bash
dbt compile --select monthly_revenue_analysis
docker exec -i postgres_dw psql -U dbt_user -d my_warehouse \
  < target/compiled/experiment/analyses/monthly_revenue_analysis.sql
```

**Available Analyses:**
- `monthly_revenue_analysis` - MoM trends and growth rates
- `customer_cohort_analysis` - Retention by signup month
- `product_performance_report` - Product rankings and metrics
- `customer_rfm_analysis` - RFM segmentation

For detailed documentation, see [ADVANCED_FEATURES.md](ADVANCED_FEATURES.md).

---

## 🛠️ Development

### Development Workflow

```bash
# 1. Make changes to models
vim models/marts/dim_customers.sql

# 2. Run the model
dbt run --select dim_customers

# 3. Test the model
dbt test --select dim_customers

# 4. Check compiled SQL
cat target/compiled/experiment/models/marts/dim_customers.sql

# 5. View documentation
dbt docs generate && dbt docs serve
```

### Adding New Models

1. Create SQL file in appropriate folder
2. Add to schema.yml with description and tests
3. Run and test: `dbt run --select your_model && dbt test --select your_model`

### Best Practices

- ✅ Use `ref()` for model dependencies, not direct table references
- ✅ Add tests for all primary keys and foreign keys
- ✅ Document models and columns in schema.yml
- ✅ Use staging layer for all source data
- ✅ Keep business logic in intermediate layer
- ✅ Materialize marts as tables for performance
- ✅ Use consistent naming conventions (stg_, int_, fct_, dim_)

### Project Configuration

Key settings in `dbt_project.yml`:

```yaml
models:
  experiment:
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +materialized: table
      +schema: marts
```

---

## 🐛 Troubleshooting

### Common Issues

**1. Connection Errors**

```bash
# Verify database is running
docker ps | grep postgres

# Check connection
dbt debug

# Verify credentials match docker-compose.yaml
cat profiles.yml
```

**2. Raw Tables Don't Exist**

```bash
# Reset database to run init scripts
docker-compose down -v
docker-compose up -d db
sleep 5  # Wait for initialization

# Verify tables exist
docker exec postgres_dw psql -U dbt_user -d my_warehouse -c "\dt"
```

**3. Models Not Rebuilding**

```bash
# Clear artifacts and rebuild
dbt clean
dbt run --full-refresh
```

**4. Tests Failing**

```bash
# Run tests with verbose output
dbt test --select failing_test_name --store-failures

# Check failed records (if store-failures enabled)
docker exec postgres_dw psql -U dbt_user -d my_warehouse \
  -c "SELECT * FROM analytics.failing_test_name_failures;"
```

**5. Port Already in Use**

```bash
# Check what's using port 5432
lsof -i :5432

# Change port in docker-compose.yaml if needed
# ports:
#   - "5433:5432"  # Map to different local port
```

### Logs

```bash
# dbt logs
cat logs/dbt.log

# PostgreSQL logs
docker-compose logs db

# Follow logs in real-time
docker-compose logs -f db
```

---

## 📚 Additional Resources

### Documentation

- [SETUP_GUIDE.md](../SETUP_GUIDE.md) - Detailed setup instructions
- [ADVANCED_FEATURES.md](ADVANCED_FEATURES.md) - Deep dive into macros, snapshots, tests, analyses
- [ECOMMERCE_ETL_README.md](ECOMMERCE_ETL_README.md) - Original ETL documentation

### Connection Details

- **Host:** localhost
- **Port:** 5432
- **Database:** my_warehouse
- **User:** dbt_user
- **Password:** dbt_password
- **Schemas:**
  - `public` - Raw source data
  - `analytics_staging` - Staging views
  - `analytics_intermediate` - Intermediate views
  - `analytics_marts` - Fact and dimension tables
  - `snapshots` - Historical tracking

### External Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [dbt Discourse](https://discourse.getdbt.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## 📈 Sample Data

### Data Volumes

- **Customers:** 5 sample customers
- **Products:** 8 products across Electronics, Furniture, Office Supplies
- **Orders:** 7 orders with various statuses
- **Order Items:** 14 line items

### Key Metrics (Sample Data)

```
Total Revenue:     $5,033
Total Profit:      $2,008
Avg Order Value:   $719
Profit Margin:     39.9%
```

### Customer Segments

```
Regular:   2 customers (40%)
One-time:  3 customers (60%)
```

### Top Products

```
1. Laptop Pro 15    - $3,899 revenue
2. Standing Desk    - $599 revenue
3. Office Chair     - $499 revenue
```

---

## 🤝 Contributing

To extend this project:

1. Add new models to appropriate layer (staging/intermediate/marts)
2. Add tests in schema.yml or tests/
3. Document changes in schema.yml
4. Run `dbt run && dbt test` to verify
5. Update this README if adding major features

---

## 📝 License

This is a demonstration project for educational purposes.

---

## 💡 Next Steps

- [ ] Add incremental models for large fact tables
- [ ] Implement slowly changing dimensions (Type 2)
- [ ] Add data freshness checks
- [ ] Set up orchestration (Airflow/Dagster)
- [ ] Connect BI tool (Tableau/Metabase)
- [ ] Add more custom macros for your business
- [ ] Create additional analyses and reports
- [ ] Implement data quality monitoring
- [ ] Add CI/CD pipeline
- [ ] Set up production deployment

---

**Built with ❤️ using dbt**

Last updated: 2026-01-21
