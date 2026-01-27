{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ ref('stem_combinations') }}
),

renamed as (
    select
        track_path,
        replaced_stem_type,
        replacing_stem_type,
        replacing_stem_path,
        similarity_score,
        -- Add computed fields
        case
            when similarity_score >= 0.9 then 'high'
            when similarity_score >= 0.75 then 'medium'
            else 'low'
        end as similarity_category,
        -- Extract folder from S3 path
        split_part(track_path, '/', 4) as track_folder,
        split_part(replacing_stem_path, '/', 4) as replacing_folder
    from source
)

select * from renamed
