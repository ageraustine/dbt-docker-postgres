{% macro get_date_parts(date_column) %}
    extract(year from {{ date_column }}) as year,
    extract(month from {{ date_column }}) as month,
    extract(day from {{ date_column }}) as day,
    extract(quarter from {{ date_column }}) as quarter,
    to_char({{ date_column }}, 'Day') as day_of_week,
    to_char({{ date_column }}, 'Month') as month_name
{% endmacro %}

{% macro get_fiscal_year(date_column, fiscal_year_start_month=1) %}
    case
        when extract(month from {{ date_column }}) >= {{ fiscal_year_start_month }}
        then extract(year from {{ date_column }})
        else extract(year from {{ date_column }}) - 1
    end
{% endmacro %}
