{{
    config(
        materialized='table'
    )
}}

with combinations as (
    select * from {{ ref('int_quality_scored') }}
),

family_stats as (
    select
        replaced_stem_family,
        replacing_stem_family,
        count(*) as total_combinations,
        count(case when quality_tier = 'excellent' then 1 end) as excellent_count,
        count(case when quality_tier = 'good' then 1 end) as good_count,
        count(case when quality_tier = 'acceptable' then 1 end) as acceptable_count,
        count(case when quality_tier = 'poor' then 1 end) as poor_count,
        avg(similarity_score) as avg_similarity,
        avg(composite_quality_score) as avg_quality_score,
        max(similarity_score) as max_similarity,
        min(similarity_score) as min_similarity
    from combinations
    where replaced_stem_family is not null
      and replacing_stem_family is not null
    group by replaced_stem_family, replacing_stem_family
)

select
    replaced_stem_family,
    replacing_stem_family,
    total_combinations,
    excellent_count,
    good_count,
    acceptable_count,
    poor_count,
    round(avg_similarity::numeric, 3) as avg_similarity,
    round(avg_quality_score::numeric, 2) as avg_quality_score,
    round(max_similarity::numeric, 3) as max_similarity,
    round(min_similarity::numeric, 3) as min_similarity,
    round((excellent_count + good_count)::numeric / total_combinations * 100, 2) as pct_high_quality,
    case
        when replaced_stem_family = replacing_stem_family then 'Same Family'
        else 'Cross Family'
    end as replacement_type
from family_stats
order by avg_quality_score desc, total_combinations desc
