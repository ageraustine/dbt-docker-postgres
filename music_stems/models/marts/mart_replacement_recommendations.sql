{{
    config(
        materialized='table'
    )
}}

-- This model provides actionable replacement recommendations
-- Only showing high-quality options (excellent or good tier)

with best_combinations as (
    select * from {{ ref('int_best_combinations_per_track') }}
),

high_quality_only as (
    select
        track_path,
        genre,
        mood,
        energy,
        key,
        tempo,
        replaced_stem_type,
        replaced_stem_family,
        replacing_stem_type,
        replacing_stem_family,
        replacing_stem_path,
        similarity_score,
        composite_quality_score,
        quality_tier,
        same_family_replacement,
        rank_within_stem
    from best_combinations
    where quality_tier in ('excellent', 'good')
      and rank_within_stem = 1  -- Only best option per stem
),

with_recommendation_text as (
    select
        *,
        case
            when quality_tier = 'excellent' and same_family_replacement then
                'Highly Recommended: Excellent match within same family'
            when quality_tier = 'excellent' and not same_family_replacement then
                'Recommended: Excellent cross-family match'
            when quality_tier = 'good' and same_family_replacement then
                'Recommended: Good match within same family'
            when quality_tier = 'good' and not same_family_replacement then
                'Consider: Good cross-family match'
            else 'Review: Check compatibility'
        end as recommendation,

        case
            when similarity_score >= 0.95 then 5
            when similarity_score >= 0.90 then 4
            when similarity_score >= 0.85 then 3
            when similarity_score >= 0.80 then 2
            else 1
        end as recommendation_priority
    from high_quality_only
)

select * from with_recommendation_text
order by recommendation_priority desc, composite_quality_score desc
