# E-Commerce ETL Setup Guide with Docker

This guide shows you how to run the e-commerce ETL system using PostgreSQL in Docker and dbt locally.

## Architecture

```
PostgreSQL (Docker) <---> dbt (Local) ---> Analytics Tables
```

## Quick Start

### 1. Start PostgreSQL Database

```bash
docker-compose up -d db
```

This will:
- Start PostgreSQL on port 5432
- Automatically create raw tables (raw_customers, raw_products, raw_orders, raw_order_items)
- Load sample e-commerce data
- Create an `analytics` schema for dbt models

### 2. Verify Database is Running

```bash
docker ps
```

You should see `postgres_dw` container running.

### 3. Test Database Connection

```bash
docker exec -it postgres_dw psql -U dbt_user -d my_warehouse
```

Once connected, you can check the data:
```sql
\dt                          -- List all tables
SELECT COUNT(*) FROM raw_customers;
SELECT COUNT(*) FROM raw_orders;
\q                           -- Exit psql
```

### 4. Set up dbt Profile

Copy the profiles.yml to your dbt profiles directory:

```bash
# On macOS/Linux
mkdir -p ~/.dbt
cp experiment/profiles.yml ~/.dbt/profiles.yml

# Or use the local one (set DBT_PROFILES_DIR)
export DBT_PROFILES_DIR=/Users/macbook/Desktop/rnd/dbts/experiment
```

### 5. Test dbt Connection

```bash
cd experiment
dbt debug
```

You should see all connection checks pass.

### 6. Run the ETL Pipeline

```bash
# Run all models
dbt run

# Run by layer
dbt run --select staging
dbt run --select intermediate
dbt run --select marts

# Run specific model
dbt run --select dim_customers
```

### 7. Test Data Quality

```bash
dbt test
```

### 8. Generate Documentation

```bash
dbt docs generate
dbt docs serve
```

Open http://localhost:8080 in your browser to view the lineage graph and documentation.

## Project Structure

```
dbts/
├── docker-compose.yaml           # PostgreSQL container
├── init-scripts/                 # Auto-loaded on first start
│   ├── 01_create_tables.sql
│   └── 02_load_sample_data.sql
└── experiment/                   # dbt project
    ├── dbt_project.yml
    ├── profiles.yml             # Database connection config
    └── models/
        ├── staging/             # Views in analytics.staging
        ├── intermediate/        # Views in analytics.intermediate
        └── marts/              # Tables in analytics.marts
```

## Connection Details

- **Host**: localhost
- **Port**: 5432
- **Database**: my_warehouse
- **User**: dbt_user
- **Password**: dbt_password
- **Raw Data Schema**: public
- **Analytics Schema**: analytics

## Available Data

### Source Tables (public schema)
- `raw_customers` - 5 sample customers
- `raw_products` - 8 sample products
- `raw_orders` - 7 sample orders
- `raw_order_items` - 14 order line items

### dbt Models (analytics schema)

**Staging** (views):
- `analytics.stg_customers`
- `analytics.stg_products`
- `analytics.stg_orders`
- `analytics.stg_order_items`

**Intermediate** (views):
- `analytics.int_order_items_joined`
- `analytics.int_customer_orders`

**Marts** (tables):
- `analytics.dim_customers` - Customer dimension with lifetime metrics
- `analytics.dim_products` - Product dimension with sales metrics
- `analytics.fct_orders` - Orders fact table

## Useful Commands

### Docker Commands

```bash
# Start database
docker-compose up -d db

# Stop database
docker-compose down

# View logs
docker-compose logs -f db

# Reset database (delete all data)
docker-compose down -v
docker-compose up -d db
```

### dbt Commands

```bash
# Run all models
dbt run

# Run tests
dbt test

# Run specific model and its dependencies
dbt run --select +dim_customers

# Run model and downstream dependencies
dbt run --select stg_customers+

# Compile SQL without running
dbt compile

# Generate and view docs
dbt docs generate && dbt docs serve
```

## Querying the Results

Connect to the database:
```bash
docker exec -it postgres_dw psql -U dbt_user -d my_warehouse
```

Example queries:
```sql
-- View customer segments
SELECT customer_segment, COUNT(*)
FROM analytics.dim_customers
GROUP BY customer_segment;

-- Top products by revenue
SELECT product_name, total_revenue
FROM analytics.dim_products
ORDER BY total_revenue DESC
LIMIT 5;

-- Order metrics
SELECT
    COUNT(*) as total_orders,
    SUM(order_revenue) as total_revenue,
    AVG(order_profit) as avg_profit
FROM analytics.fct_orders;
```

## Troubleshooting

### Can't connect to PostgreSQL
- Ensure container is running: `docker ps`
- Check if port 5432 is available: `lsof -i :5432`
- Wait a few seconds after starting for PostgreSQL to be ready

### dbt connection errors
- Verify profiles.yml is in the right location
- Test connection: `dbt debug`
- Check credentials match docker-compose.yaml

### Tables not created
- Check init scripts ran: `docker-compose logs db`
- If needed, reset: `docker-compose down -v && docker-compose up -d db`

## Next Steps

1. Explore the dbt documentation (dbt docs serve)
2. Connect a BI tool (Tableau, Metabase, etc.) to analytics schema
3. Modify models to add your own business logic
4. Replace sample data with real data sources
5. Set up incremental models for production use
