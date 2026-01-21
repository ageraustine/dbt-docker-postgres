{{
    config(
        materialized='table'
    )
}}

with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select * from {{ ref('int_customer_orders') }}
),

customer_metrics as (
    select
        customer_id,
        count(distinct order_id) as lifetime_orders,
        sum(order_revenue) as lifetime_revenue,
        sum(order_profit) as lifetime_profit,
        avg(order_revenue) as avg_order_value,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date
    from customer_orders
    group by customer_id
),

final as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.address,
        c.city,
        c.state,
        c.zip_code,
        c.country,
        c.created_at as customer_created_at,

        -- Customer metrics
        coalesce(cm.lifetime_orders, 0) as lifetime_orders,
        coalesce(cm.lifetime_revenue, 0) as lifetime_revenue,
        coalesce(cm.lifetime_profit, 0) as lifetime_profit,
        coalesce(cm.avg_order_value, 0) as avg_order_value,
        cm.first_order_date,
        cm.last_order_date,

        -- Customer segments
        case
            when cm.lifetime_orders >= 10 then 'VIP'
            when cm.lifetime_orders >= 5 then 'Loyal'
            when cm.lifetime_orders >= 2 then 'Regular'
            when cm.lifetime_orders = 1 then 'One-time'
            else 'New'
        end as customer_segment
    from customers c
    left join customer_metrics cm on c.customer_id = cm.customer_id
)

select * from final
