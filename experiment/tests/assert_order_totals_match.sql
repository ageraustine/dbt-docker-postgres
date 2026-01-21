-- Test to ensure order totals match the sum of line items
-- This test will fail if there are any discrepancies

with order_totals as (
    select
        order_id,
        total_amount as order_total
    from {{ ref('stg_orders') }}
),

calculated_totals as (
    select
        order_id,
        sum(line_total) as calculated_total
    from {{ ref('stg_order_items') }}
    group by order_id
),

comparison as (
    select
        ot.order_id,
        ot.order_total,
        ct.calculated_total,
        abs(ot.order_total - ct.calculated_total) as difference
    from order_totals ot
    join calculated_totals ct on ot.order_id = ct.order_id
    where abs(ot.order_total - ct.calculated_total) > 0.01  -- Allow for rounding
)

select * from comparison
