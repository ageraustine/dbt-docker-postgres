{{
    config(
        materialized='table'
    )
}}

with stem_combinations as (
    select * from {{ ref('stg_stem_combinations') }}
),

compatibility_stats as (
    select
        replaced_stem_type,
        replacing_stem_type,
        count(*) as combination_count,
        avg(similarity_score) as avg_similarity,
        min(similarity_score) as min_similarity,
        max(similarity_score) as max_similarity,
        count(case when similarity_score >= 0.9 then 1 end) as high_similarity_count,
        count(case when similarity_score >= 0.75 then 1 end) as medium_similarity_count
    from stem_combinations
    group by replaced_stem_type, replacing_stem_type
)

select
    replaced_stem_type,
    replacing_stem_type,
    combination_count,
    round(avg_similarity::numeric, 3) as avg_similarity,
    round(min_similarity::numeric, 3) as min_similarity,
    round(max_similarity::numeric, 3) as max_similarity,
    high_similarity_count,
    medium_similarity_count,
    round((high_similarity_count::numeric / combination_count * 100), 2) as pct_high_similarity
from compatibility_stats
order by combination_count desc, avg_similarity desc
