{% macro calculate_profit_margin(revenue_column, cost_column) %}
    case
        when {{ revenue_column }} > 0
        then round((({{ revenue_column }} - {{ cost_column }}) / {{ revenue_column }}) * 100, 2)
        else 0
    end
{% endmacro %}

{% macro calculate_days_since(date_column) %}
    (current_date - {{ date_column }}::date)
{% endmacro %}

{% macro cents_to_dollars(cents_column) %}
    round({{ cents_column }} / 100.0, 2)
{% endmacro %}

{% macro generate_surrogate_key(columns) %}
    md5({% for col in columns %}cast({{ col }} as varchar){% if not loop.last %} || '|' || {% endif %}{% endfor %})
{% endmacro %}
