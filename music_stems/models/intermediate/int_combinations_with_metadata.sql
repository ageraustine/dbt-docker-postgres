{{
    config(
        materialized='view'
    )
}}

with combinations as (
    select * from {{ ref('stg_stem_combinations') }}
),

track_metadata as (
    select * from {{ ref('track_metadata') }}
),

enriched as (
    select
        c.*,
        t.genre,
        t.mood,
        t.energy,
        t.key,
        t.tempo,
        t.source
    from combinations c
    left join track_metadata t
        on c.track_path = t.track_path
)

select * from enriched
