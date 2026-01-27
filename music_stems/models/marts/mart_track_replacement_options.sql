{{
    config(
        materialized='table'
    )
}}

with stem_combinations as (
    select * from {{ ref('stg_stem_combinations') }}
),

track_stats as (
    select
        track_path,
        count(*) as total_replacement_options,
        count(distinct replaced_stem_type) as stems_with_replacements,
        count(distinct replacing_stem_type) as unique_replacing_stems,
        avg(similarity_score) as avg_similarity,
        max(similarity_score) as best_similarity,
        count(case when similarity_category = 'high' then 1 end) as high_quality_options,
        count(case when similarity_category = 'medium' then 1 end) as medium_quality_options
    from stem_combinations
    group by track_path
)

select
    track_path,
    total_replacement_options,
    stems_with_replacements,
    unique_replacing_stems,
    round(avg_similarity::numeric, 3) as avg_similarity,
    round(best_similarity::numeric, 3) as best_similarity,
    high_quality_options,
    medium_quality_options,
    round((high_quality_options::numeric / total_replacement_options * 100), 2) as pct_high_quality
from track_stats
order by total_replacement_options desc
