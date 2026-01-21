{% snapshot product_price_snapshot %}

{{
    config(
      target_schema='snapshots',
      unique_key='product_id',
      strategy='check',
      check_cols=['price', 'cost'],
    )
}}

select
    product_id,
    product_name,
    category,
    brand,
    price,
    cost,
    updated_at
from {{ ref('stg_products') }}

{% endsnapshot %}
