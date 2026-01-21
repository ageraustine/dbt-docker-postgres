-- Test to ensure all orders have valid status values

select
    order_id,
    status
from {{ ref('stg_orders') }}
where status not in ('pending', 'processing', 'shipped', 'completed', 'cancelled', 'refunded')
