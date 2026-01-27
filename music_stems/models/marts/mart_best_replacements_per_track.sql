{{
    config(
        materialized='table'
    )
}}

with best_combinations as (
    select * from {{ ref('int_best_combinations_per_track') }}
),

final as (
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
        rank_within_stem,
        similarity_score,
        composite_quality_score,
        quality_tier,
        same_family_replacement,
        similarity_category
    from best_combinations
)

select * from final
order by track_path, replaced_stem_type, rank_within_stem
