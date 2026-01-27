{{
    config(
        materialized='view'
    )
}}

with combinations as (
    select * from {{ ref('int_combinations_with_metadata') }}
),

stem_families as (
    select * from {{ ref('stem_family_mapping') }}
),

with_families as (
    select
        c.*,
        f1.stem_family as replaced_stem_family,
        f2.stem_family as replacing_stem_family
    from combinations c
    left join stem_families f1
        on lower(trim(c.replaced_stem_type)) = lower(trim(f1.stem_type))
    left join stem_families f2
        on lower(trim(c.replacing_stem_type)) = lower(trim(f2.stem_type))
)

select * from with_families
