{% macro create_helper_functions() %}
-- Safe casts used by stg_complaints_clean: return NULL instead of erroring on bad values.
-- Previously created by hand (Supabase script 01); now owned by dbt via on-run-start.

CREATE OR REPLACE FUNCTION public.try_cast_date(text) RETURNS date AS $$
BEGIN
    RETURN $1::date;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.try_cast_bigint(text) RETURNS bigint AS $$
BEGIN
    RETURN $1::bigint;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

{% endmacro %}