-- Test to ensure all products have positive prices

select
    product_id,
    product_name,
    price,
    cost
from {{ ref('stg_products') }}
where price <= 0 or cost < 0
