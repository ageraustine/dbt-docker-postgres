{{
    config(
        materialized='table'
    )
}}

with customer_orders as (
    select * from {{ ref('int_customer_orders') }}
),

final as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        products_count,
        total_quantity,
        order_revenue,
        order_cost,
        order_profit,
        case
            when order_revenue > 0 then (order_profit / order_revenue) * 100
            else 0
        end as profit_margin_pct,
        created_at
    from customer_orders
)

select * from final
