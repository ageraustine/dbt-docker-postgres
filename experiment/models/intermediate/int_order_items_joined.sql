with order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

joined as (
    select
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        oi.quantity,
        oi.unit_price,
        oi.discount_amount,
        oi.line_total,

        -- Product details
        p.product_name,
        p.category,
        p.subcategory,
        p.brand,
        p.cost as product_cost,

        -- Order details
        o.customer_id,
        o.order_date,
        o.status as order_status,

        -- Calculated fields
        (oi.quantity * p.cost) as total_cost,
        (oi.line_total - (oi.quantity * p.cost)) as gross_profit,

        oi.created_at
    from order_items oi
    left join products p on oi.product_id = p.product_id
    left join orders o on oi.order_id = o.order_id
)

select * from joined
