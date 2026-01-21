with source as (
    select * from {{ source('ecommerce', 'raw_products') }}
),

renamed as (
    select
        id as product_id,
        name as product_name,
        category,
        subcategory,
        brand,
        price,
        cost,
        stock_quantity,
        created_at,
        updated_at
    from source
)

select * from renamed
