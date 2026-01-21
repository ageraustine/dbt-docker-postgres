{% macro validate_email(email_column) %}
    {{ email_column }} ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
{% endmacro %}

{% macro validate_positive(column) %}
    {{ column }} >= 0
{% endmacro %}

{% macro validate_phone_us(phone_column) %}
    {{ phone_column }} ~ '^[0-9]{3}-[0-9]{4}$'
{% endmacro %}
