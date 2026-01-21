with source as (
    select * from {{ source('ecommerce', 'raw_order_items') }}
),

renamed as (
    select
        id as order_item_id,
        order_id,
        product_id,
        quantity,
        unit_price,
        discount_amount,
        line_total,
        created_at
    from source
)

select * from renamed
