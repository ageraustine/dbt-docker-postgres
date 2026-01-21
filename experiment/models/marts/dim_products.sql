{{
    config(
        materialized='table'
    )
}}

with products as (
    select * from {{ ref('stg_products') }}
),

product_orders as (
    select * from {{ ref('int_order_items_joined') }}
),

product_metrics as (
    select
        product_id,
        count(distinct order_id) as times_ordered,
        sum(quantity) as total_quantity_sold,
        sum(line_total) as total_revenue,
        sum(gross_profit) as total_profit,
        avg(unit_price) as avg_selling_price
    from product_orders
    group by product_id
),

final as (
    select
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        p.brand,
        p.price as current_price,
        p.cost as current_cost,
        p.stock_quantity,
        p.created_at as product_created_at,

        -- Product performance metrics
        coalesce(pm.times_ordered, 0) as times_ordered,
        coalesce(pm.total_quantity_sold, 0) as total_quantity_sold,
        coalesce(pm.total_revenue, 0) as total_revenue,
        coalesce(pm.total_profit, 0) as total_profit,
        coalesce(pm.avg_selling_price, 0) as avg_selling_price,

        -- Product classification
        case
            when pm.total_quantity_sold >= 100 then 'Best Seller'
            when pm.total_quantity_sold >= 50 then 'Popular'
            when pm.total_quantity_sold >= 10 then 'Moderate'
            when pm.total_quantity_sold > 0 then 'Slow Moving'
            else 'No Sales'
        end as product_performance
    from products p
    left join product_metrics pm on p.product_id = pm.product_id
)

select * from final
