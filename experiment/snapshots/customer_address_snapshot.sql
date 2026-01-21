{% snapshot customer_address_snapshot %}

{{
    config(
      target_schema='snapshots',
      unique_key='customer_id',
      strategy='check',
      check_cols=['address', 'city', 'state', 'zip_code', 'country'],
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    address,
    city,
    state,
    zip_code,
    country,
    updated_at
from {{ ref('stg_customers') }}

{% endsnapshot %}
