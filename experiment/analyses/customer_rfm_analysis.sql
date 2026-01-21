-- RFM Analysis (Recency, Frequency, Monetary)
-- Segment customers based on purchasing behavior

with rfm_metrics as (
    select
        customer_id,
        first_name || ' ' || last_name as customer_name,

        -- Recency: Days since last order
        {{ calculate_days_since('last_order_date') }} as recency_days,

        -- Frequency: Number of orders
        lifetime_orders as frequency,

        -- Monetary: Total revenue
        lifetime_revenue as monetary
    from {{ ref('dim_customers') }}
    where last_order_date is not null
),

rfm_scores as (
    select
        customer_id,
        customer_name,
        recency_days,
        frequency,
        monetary,

        -- Score each dimension on 1-5 scale
        ntile(5) over (order by recency_days desc) as recency_score,
        ntile(5) over (order by frequency) as frequency_score,
        ntile(5) over (order by monetary) as monetary_score
    from rfm_metrics
),

rfm_segments as (
    select
        *,
        (recency_score + frequency_score + monetary_score) as rfm_total_score,
        recency_score::text || frequency_score::text || monetary_score::text as rfm_code,

        -- Segment customers
        case
            when recency_score >= 4 and frequency_score >= 4 and monetary_score >= 4
                then 'Champions'
            when recency_score >= 3 and frequency_score >= 3 and monetary_score >= 3
                then 'Loyal Customers'
            when recency_score >= 4 and frequency_score <= 2
                then 'New Customers'
            when recency_score <= 2 and frequency_score >= 4
                then 'At Risk'
            when recency_score <= 2 and frequency_score <= 2
                then 'Lost'
            when monetary_score >= 4
                then 'Big Spenders'
            else 'Others'
        end as customer_rfm_segment
    from rfm_scores
)

select
    customer_name,
    recency_days,
    frequency,
    round(monetary, 2) as monetary,
    rfm_code,
    rfm_total_score,
    customer_rfm_segment
from rfm_segments
order by rfm_total_score desc, monetary desc
