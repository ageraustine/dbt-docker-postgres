{{
    config(
        materialized='table'
    )
}}

with combinations as (
    select * from {{ ref('int_quality_scored') }}
),

key_tempo_groups as (
    select
        key,
        -- Group tempos into ranges
        case
            when tempo < 80 then 'Slow (< 80 BPM)'
            when tempo >= 80 and tempo < 110 then 'Medium (80-110 BPM)'
            when tempo >= 110 and tempo < 140 then 'Upbeat (110-140 BPM)'
            when tempo >= 140 then 'Fast (>= 140 BPM)'
            else 'Unknown'
        end as tempo_range,
        count(*) as total_combinations,
        count(distinct track_path) as unique_tracks,
        avg(similarity_score) as avg_similarity,
        avg(composite_quality_score) as avg_quality_score,
        count(case when quality_tier = 'excellent' then 1 end) as excellent_count,
        count(case when quality_tier = 'good' then 1 end) as good_count
    from combinations
    where key is not null and tempo is not null
    group by key, tempo_range
)

select
    key,
    tempo_range,
    total_combinations,
    unique_tracks,
    round(avg_similarity::numeric, 3) as avg_similarity,
    round(avg_quality_score::numeric, 2) as avg_quality_score,
    excellent_count,
    good_count,
    round(((excellent_count + good_count)::numeric / total_combinations * 100), 2) as pct_high_quality
from key_tempo_groups
order by key, tempo_range
