{{
    config(
        materialized='view'
    )
}}

with scored_combinations as (
    select * from {{ ref('int_quality_scored') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by track_path, replaced_stem_type
            order by composite_quality_score desc, similarity_score desc
        ) as rank_within_stem
    from scored_combinations
),

-- Get top 3 replacements for each stem in each track
top_replacements as (
    select *
    from ranked
    where rank_within_stem <= 3
)

select * from top_replacements
