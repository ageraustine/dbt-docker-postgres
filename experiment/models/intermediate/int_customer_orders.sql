with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('int_order_items_joined') }}
),

customer_order_summary as (
    select
        o.customer_id,
        o.order_id,
        o.order_date,
        o.status,
        o.total_amount,

        -- Aggregated order item metrics
        count(distinct oi.product_id) as products_count,
        sum(oi.quantity) as total_quantity,
        sum(oi.line_total) as order_revenue,
        sum(oi.total_cost) as order_cost,
        sum(oi.gross_profit) as order_profit,

        o.created_at
    from orders o
    left join order_items oi on o.order_id = oi.order_id
    group by
        o.customer_id,
        o.order_id,
        o.order_date,
        o.status,
        o.total_amount,
        o.created_at
)

select * from customer_order_summary
