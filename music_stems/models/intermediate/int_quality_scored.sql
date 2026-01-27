{{
    config(
        materialized='view'
    )
}}

with combinations as (
    select * from {{ ref('int_combinations_with_families') }}
),

scored as (
    select
        *,
        -- Quality score based on multiple factors
        case
            when similarity_score >= 0.95 then 'excellent'
            when similarity_score >= 0.85 then 'good'
            when similarity_score >= 0.75 then 'acceptable'
            else 'poor'
        end as quality_tier,

        -- Compatibility flag - same family is generally safer
        case
            when replaced_stem_family = replacing_stem_family then true
            else false
        end as same_family_replacement,

        -- Calculate a composite quality score (0-100)
        round(
            (similarity_score * 70 +  -- 70% weight on similarity
            case when replaced_stem_family = replacing_stem_family then 30 else 0 end) -- 30% bonus for same family
        , 2) as composite_quality_score

    from combinations
)

select * from scored
