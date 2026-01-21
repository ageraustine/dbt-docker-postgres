-- Customer Cohort Analysis
-- Analyzes customer behavior by their first order month

with customer_cohorts as (
    select
        customer_id,
        date_trunc('month', first_order_date) as cohort_month
    from {{ ref('dim_customers') }}
    where first_order_date is not null
),

cohort_metrics as (
    select
        c.cohort_month,
        count(distinct c.customer_id) as cohort_size,
        sum(dc.lifetime_orders) as total_orders,
        sum(dc.lifetime_revenue) as total_revenue,
        avg(dc.lifetime_orders) as avg_orders_per_customer,
        avg(dc.lifetime_revenue) as avg_revenue_per_customer,

        -- Customer retention by segment
        count(distinct case when dc.customer_segment = 'VIP' then c.customer_id end) as vip_customers,
        count(distinct case when dc.customer_segment = 'Loyal' then c.customer_id end) as loyal_customers,
        count(distinct case when dc.customer_segment = 'Regular' then c.customer_id end) as regular_customers,
        count(distinct case when dc.customer_segment = 'One-time' then c.customer_id end) as onetime_customers
    from customer_cohorts c
    join {{ ref('dim_customers') }} dc on c.customer_id = dc.customer_id
    group by c.cohort_month
)

select
    to_char(cohort_month, 'YYYY-MM') as cohort,
    cohort_size,
    total_orders,
    round(total_revenue, 2) as total_revenue,
    round(avg_orders_per_customer, 2) as avg_orders_per_customer,
    round(avg_revenue_per_customer, 2) as avg_ltv,
    vip_customers,
    loyal_customers,
    regular_customers,
    onetime_customers,
    round((onetime_customers::numeric / cohort_size) * 100, 2) as churn_rate_pct
from cohort_metrics
order by cohort_month desc
