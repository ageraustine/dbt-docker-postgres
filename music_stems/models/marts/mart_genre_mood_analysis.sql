{{
    config(
        materialized='table'
    )
}}

with combinations as (
    select * from {{ ref('int_quality_scored') }}
),

genre_mood_stats as (
    select
        genre,
        mood,
        energy,
        count(*) as total_combinations,
        count(distinct track_path) as unique_tracks,
        count(distinct replaced_stem_type) as stem_types_replaced,
        count(distinct replacing_stem_type) as unique_replacement_stems,
        avg(similarity_score) as avg_similarity,
        avg(composite_quality_score) as avg_quality_score,
        count(case when quality_tier in ('excellent', 'good') then 1 end) as high_quality_count
    from combinations
    where genre is not null
    group by genre, mood, energy
)

select
    genre,
    mood,
    energy,
    total_combinations,
    unique_tracks,
    stem_types_replaced,
    unique_replacement_stems,
    round(avg_similarity::numeric, 3) as avg_similarity,
    round(avg_quality_score::numeric, 2) as avg_quality_score,
    high_quality_count,
    round((high_quality_count::numeric / total_combinations * 100), 2) as pct_high_quality
from genre_mood_stats
order by total_combinations desc
