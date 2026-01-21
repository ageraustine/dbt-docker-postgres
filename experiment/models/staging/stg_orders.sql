with source as (
    select * from {{ source('ecommerce', 'raw_orders') }}
),

renamed as (
    select
        id as order_id,
        customer_id,
        order_date,
        status,
        total_amount,
        shipping_address,
        shipping_city,
        shipping_state,
        shipping_zip_code,
        shipping_country,
        created_at,
        updated_at
    from source
)

select * from renamed
