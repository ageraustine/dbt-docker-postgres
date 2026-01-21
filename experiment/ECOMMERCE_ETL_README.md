# E-Commerce ETL System

A simple dbt-based ETL system for e-commerce analytics.

## Architecture

### Data Flow
```
Raw Data → Staging → Intermediate → Marts (Fact & Dimensions)
```

### Layer Structure

#### 1. Staging Layer (`models/staging/`)
Standardizes raw data with consistent naming and light cleaning:
- `stg_customers` - Customer data
- `stg_products` - Product catalog
- `stg_orders` - Order transactions
- `stg_order_items` - Order line items

#### 2. Intermediate Layer (`models/intermediate/`)
Business logic transformations and joins:
- `int_order_items_joined` - Order items with product and order details, profit calculations
- `int_customer_orders` - Aggregated order metrics by customer

#### 3. Marts Layer (`models/marts/`)
Final analytical models for reporting:
- `fct_orders` - Orders fact table with key metrics
- `dim_customers` - Customer dimension with lifetime value and segmentation
- `dim_products` - Product dimension with sales performance

## Getting Started

### 1. Configure Your Data Source

Update `models/staging/sources.yml` with your actual database and schema names:
```yaml
sources:
  - name: ecommerce
    database: your_database_name  # Update this
    schema: your_schema_name      # Update this
```

### 2. Load Sample Data (Optional)

For testing, load the seed files:
```bash
dbt seed
```

This will create tables from the CSV files in `seeds/`:
- `raw_customers`
- `raw_products`
- `raw_orders`
- `raw_order_items`

### 3. Run the ETL Pipeline

Build all models:
```bash
dbt run
```

Or run specific layers:
```bash
dbt run --select staging      # Run staging models only
dbt run --select intermediate # Run intermediate models only
dbt run --select marts        # Run marts models only
```

### 4. Test Data Quality

Run tests defined in schema files:
```bash
dbt test
```

### 5. Generate Documentation

Create and serve documentation:
```bash
dbt docs generate
dbt docs serve
```

## Key Metrics Available

### Customer Analytics (`dim_customers`)
- Lifetime orders and revenue
- Customer segmentation (VIP, Loyal, Regular, One-time, New)
- Average order value
- First and last order dates

### Product Analytics (`dim_products`)
- Total units sold and revenue
- Product performance classification
- Sales metrics and profitability

### Order Analytics (`fct_orders`)
- Order-level revenue and profit
- Profit margins
- Product count per order

## Customization

### Adding New Models

1. Create SQL file in appropriate layer
2. Add documentation in `schema.yml`
3. Update model references as needed

### Modifying Materializations

Edit `dbt_project.yml` to change how models are built:
- `view` - Fast, no storage, computed on query
- `table` - Slower builds, faster queries
- `incremental` - For large datasets (not included in this simple version)

## Next Steps

- Connect to your actual data warehouse
- Replace seed data with real source tables
- Add more business logic as needed
- Set up data quality tests
- Create BI tool dashboards using the marts tables
