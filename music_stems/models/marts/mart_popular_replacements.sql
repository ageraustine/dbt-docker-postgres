{{
    config(
        materialized='table'
    )
}}

with stem_combinations as (
    select * from {{ ref('stg_stem_combinations') }}
),

popular_stems as (
    select
        replacing_stem_type,
        replacing_stem_path,
        replacing_folder,
        count(*) as times_used_as_replacement,
        count(distinct track_path) as unique_tracks,
        count(distinct replaced_stem_type) as stem_types_replaced,
        avg(similarity_score) as avg_similarity,
        max(similarity_score) as max_similarity
    from stem_combinations
    group by replacing_stem_type, replacing_stem_path, replacing_folder
)

select
    replacing_stem_type,
    replacing_stem_path,
    replacing_folder,
    times_used_as_replacement,
    unique_tracks,
    stem_types_replaced,
    round(avg_similarity::numeric, 3) as avg_similarity,
    round(max_similarity::numeric, 3) as max_similarity
from popular_stems
order by times_used_as_replacement desc
limit 100
