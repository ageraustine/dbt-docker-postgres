-- Monthly Revenue Analysis
-- This query can be run with: dbt compile --select monthly_revenue_analysis
-- Then execute the compiled SQL in target/compiled/...

with monthly_metrics as (
    select
        date_trunc('month', order_date) as month,
        count(distinct order_id) as total_orders,
        count(distinct customer_id) as unique_customers,
        sum(order_revenue) as total_revenue,
        sum(order_profit) as total_profit,
        avg(order_revenue) as avg_order_value,
        avg(profit_margin_pct) as avg_margin_pct
    from {{ ref('fct_orders') }}
    group by date_trunc('month', order_date)
),

with_growth as (
    select
        month,
        total_orders,
        unique_customers,
        total_revenue,
        total_profit,
        avg_order_value,
        avg_margin_pct,

        -- Month-over-month growth
        lag(total_revenue) over (order by month) as prev_month_revenue,
        round(
            ((total_revenue - lag(total_revenue) over (order by month))
            / lag(total_revenue) over (order by month)) * 100,
            2
        ) as revenue_growth_pct
    from monthly_metrics
)

select
    to_char(month, 'YYYY-MM') as month,
    total_orders,
    unique_customers,
    round(total_revenue, 2) as total_revenue,
    round(total_profit, 2) as total_profit,
    round(avg_order_value, 2) as avg_order_value,
    round(avg_margin_pct, 2) as avg_margin_pct,
    revenue_growth_pct
from with_growth
order by month desc
