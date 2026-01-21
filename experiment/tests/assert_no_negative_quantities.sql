-- Test to ensure no negative quantities exist in order items

select
    order_item_id,
    order_id,
    product_id,
    quantity
from {{ ref('stg_order_items') }}
where quantity < 0
