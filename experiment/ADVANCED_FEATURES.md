# Advanced dbt Features Guide

This guide explains the advanced features added to your e-commerce ETL system.

## 📁 Folder Structure Overview

```
experiment/
├── analyses/          # Ad-hoc queries (compile but don't materialize)
├── macros/           # Reusable SQL functions
├── snapshots/        # Type 2 SCD for historical tracking
├── tests/            # Custom data quality tests
├── models/           # Your dbt models
└── seeds/            # CSV files to load
```

## 1. Macros (macros/)

**Purpose:** Reusable SQL functions to keep your code DRY (Don't Repeat Yourself)

**What's Included:**

### business_metrics.sql
- `calculate_profit_margin(revenue, cost)` - Calculates profit margin percentage
- `calculate_days_since(date_column)` - Days between date and today
- `cents_to_dollars(cents)` - Convert cents to dollars
- `generate_surrogate_key(columns)` - Create MD5 hash keys

### date_helpers.sql
- `get_date_parts(date_column)` - Extract year, month, day, quarter, etc.
- `get_fiscal_year(date_column, start_month)` - Calculate fiscal year

### data_quality.sql
- `validate_email(email)` - Check email format
- `validate_positive(column)` - Ensure non-negative values
- `validate_phone_us(phone)` - Validate US phone format

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

**Commands:**
```bash
# Macros are automatically available in all models
dbt compile --select your_model  # See compiled SQL with macros expanded
```

---

## 2. Snapshots (snapshots/)

**Purpose:** Track historical changes to dimensions (Type 2 SCD)

**What's Included:**

### product_price_snapshot
Tracks price and cost changes over time

### customer_address_snapshot
Tracks customer address changes

**How Snapshots Work:**
- First run: Captures current state
- Subsequent runs: Adds new rows when values change
- `dbt_valid_from`: When this version became active
- `dbt_valid_to`: When this version ended (NULL = current)

**Example Queries:**

```sql
-- See all historical prices for a product
SELECT
    product_name,
    price,
    cost,
    dbt_valid_from,
    dbt_valid_to
FROM snapshots.product_price_snapshot
WHERE product_id = 1
ORDER BY dbt_valid_from;

-- Get price at specific point in time
SELECT product_name, price
FROM snapshots.product_price_snapshot
WHERE product_id = 1
  AND '2024-03-15' >= dbt_valid_from
  AND ('2024-03-15' < dbt_valid_to OR dbt_valid_to IS NULL);
```

**Commands:**
```bash
dbt snapshot                    # Run all snapshots
dbt snapshot --select product_price_snapshot  # Run specific snapshot
```

**Use Cases:**
- Price change analysis
- Customer migration tracking
- Audit trails
- Point-in-time reporting

---

## 3. Custom Tests (tests/)

**Purpose:** Business-specific data quality rules

**What's Included:**

### assert_order_totals_match.sql
Ensures order.total_amount equals sum of line items

### assert_no_negative_quantities.sql
Validates all quantities are positive

### assert_positive_prices.sql
Ensures products have valid prices

### assert_valid_order_status.sql
Checks order statuses are in allowed list

**How Tests Work:**
- Test queries should return 0 rows if passing
- Any rows returned = test failure
- Tests run with `dbt test`

**Example: Create Your Own Test**

```sql
-- tests/assert_customer_has_orders.sql
-- Ensure every customer with orders exists in dim_customers

select
    o.customer_id
from {{ ref('fct_orders') }} o
left join {{ ref('dim_customers') }} c on o.customer_id = c.customer_id
where c.customer_id is null
```

**Commands:**
```bash
dbt test                          # Run all tests
dbt test --select assert_order_totals_match  # Run specific test
dbt test --select test_type:singular  # Run only custom tests
```

---

## 4. Analyses (analyses/)

**Purpose:** Ad-hoc queries that compile but don't create tables/views

**What's Included:**

### monthly_revenue_analysis.sql
Month-over-month revenue trends, growth rates

### customer_cohort_analysis.sql
Customer behavior by first order month

### product_performance_report.sql
Comprehensive product metrics with rankings

### customer_rfm_analysis.sql
RFM segmentation (Recency, Frequency, Monetary)

**How Analyses Work:**
- Compile to SQL but don't run automatically
- Use for reports, investigations, or one-time queries
- Can reference dbt models with `ref()`

**Usage:**

```bash
# 1. Compile the analysis
dbt compile --select monthly_revenue_analysis

# 2. Find compiled SQL in target/compiled/experiment/analyses/
# 3. Run it manually:
psql -U dbt_user -d my_warehouse -f target/compiled/experiment/analyses/monthly_revenue_analysis.sql

# Or use docker:
docker exec postgres_dw psql -U dbt_user -d my_warehouse -f /path/to/compiled.sql
```

**Copy-paste ready:**
```bash
dbt compile --select customer_rfm_analysis && \
docker exec -i postgres_dw psql -U dbt_user -d my_warehouse < \
target/compiled/experiment/analyses/customer_rfm_analysis.sql
```

**Analysis Examples:**

#### Monthly Revenue Analysis
Shows trends, growth rates, and key metrics by month

#### Customer Cohort Analysis
Groups customers by signup month, shows retention and LTV

#### Product Performance Report
Rankings by revenue, profit, quantity with inventory metrics

#### RFM Analysis
Segments customers into Champions, Loyal, At Risk, Lost, etc.

---

## Putting It All Together

### Typical Workflow

```bash
# 1. Run your models
dbt run

# 2. Test data quality
dbt test

# 3. Capture historical snapshots
dbt snapshot

# 4. Analyze results
dbt compile --select monthly_revenue_analysis
# Then run the compiled SQL

# 5. Generate documentation
dbt docs generate
dbt docs serve
```

### Advanced Workflow

```bash
# Run specific layer
dbt run --select staging
dbt run --select marts

# Test specific model and downstream
dbt test --select dim_customers+

# Snapshot only product prices
dbt snapshot --select product_price_snapshot

# Compile all analyses
dbt compile --select analyses
```

---

## Real-World Scenarios

### Scenario 1: Product Price Change

```bash
# 1. Update price in raw_products table
docker exec postgres_dw psql -U dbt_user -d my_warehouse \
  -c "UPDATE raw_products SET price = 1199.99 WHERE id = 1;"

# 2. Run models
dbt run

# 3. Capture the change
dbt snapshot

# 4. Query history
docker exec postgres_dw psql -U dbt_user -d my_warehouse \
  -c "SELECT * FROM snapshots.product_price_snapshot WHERE product_id = 1;"
```

### Scenario 2: Monthly Business Review

```bash
# 1. Ensure data is fresh
dbt run

# 2. Generate reports
dbt compile --select monthly_revenue_analysis
dbt compile --select product_performance_report

# 3. Run the analyses and export
docker exec postgres_dw psql -U dbt_user -d my_warehouse \
  -f /usr/app/dbt/target/compiled/.../monthly_revenue_analysis.sql \
  -o report.csv --csv
```

### Scenario 3: Data Quality Monitoring

```bash
# Run full test suite
dbt test

# If failures, investigate
dbt test --select assert_order_totals_match --store-failures

# Check failed records
docker exec postgres_dw psql -U dbt_user -d my_warehouse \
  -c "SELECT * FROM analytics.assert_order_totals_match_failures;"
```

---

## Summary Stats

**Your E-Commerce ETL System Now Has:**

- ✅ 9 Models (staging, intermediate, marts)
- ✅ 39 Data Tests (35 generic + 4 custom)
- ✅ 2 Snapshots (historical tracking)
- ✅ 4 Analyses (business reports)
- ✅ 9 Macros (reusable functions)
- ✅ 4 Source tables with validation

**Testing Coverage:**
```bash
dbt test --select marts        # Test final outputs
dbt test --select source:*     # Test raw data
dbt test --select test_type:singular  # Custom business rules
```

**Documentation:**
```bash
dbt docs generate && dbt docs serve
# View lineage graph, column descriptions, tests at http://localhost:8080
```

---

## Next Steps

1. **Add more custom tests** for your business rules
2. **Create more analyses** for specific reports you need
3. **Build additional macros** for repeated calculations
4. **Add more snapshots** for other slowly changing dimensions
5. **Schedule runs** with cron or orchestration tool (Airflow, Dagster)

## Resources

- [dbt Macros](https://docs.getdbt.com/docs/building-a-dbt-project/jinja-macros)
- [dbt Snapshots](https://docs.getdbt.com/docs/building-a-dbt-project/snapshots)
- [dbt Tests](https://docs.getdbt.com/docs/building-a-dbt-project/tests)
- [dbt Analyses](https://docs.getdbt.com/docs/building-a-dbt-project/analyses)
