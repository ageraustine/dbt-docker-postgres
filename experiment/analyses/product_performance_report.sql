-- Product Performance Report
-- Comprehensive view of product sales and profitability

with product_metrics as (
    select
        p.product_id,
        p.product_name,
        p.category,
        p.brand,
        p.current_price,
        p.current_cost,
        p.stock_quantity,
        p.total_quantity_sold,
        p.total_revenue,
        p.total_profit,
        p.product_performance,

        -- Calculate margins
        case
            when p.current_price > 0
            then round(((p.current_price - p.current_cost) / p.current_price) * 100, 2)
            else 0
        end as current_margin_pct,

        case
            when p.total_revenue > 0
            then round((p.total_profit / p.total_revenue) * 100, 2)
            else 0
        end as realized_margin_pct,

        -- Inventory metrics
        case
            when p.total_quantity_sold > 0
            then round(p.stock_quantity::numeric / p.total_quantity_sold, 2)
            else null
        end as inventory_turnover_ratio
    from {{ ref('dim_products') }} p
)

select
    product_name,
    category,
    brand,
    current_price,
    current_cost,
    stock_quantity,
    total_quantity_sold,
    round(total_revenue, 2) as total_revenue,
    round(total_profit, 2) as total_profit,
    current_margin_pct,
    realized_margin_pct,
    inventory_turnover_ratio,
    product_performance,

    -- Rank products
    row_number() over (order by total_revenue desc) as revenue_rank,
    row_number() over (order by total_profit desc) as profit_rank,
    row_number() over (order by total_quantity_sold desc) as quantity_rank
from product_metrics
order by total_revenue desc
