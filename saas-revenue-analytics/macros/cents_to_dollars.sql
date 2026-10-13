{# Consistent currency rounding used across revenue models #}
{% macro money(col) -%}
    cast(round({{ col }}, 2) as decimal(18, 2))
{%- endmacro %}
