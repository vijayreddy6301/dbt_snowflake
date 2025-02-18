{{ config(
  on_schema_change='append_new_columns',
  materialized='incremental',
) }}

-- Step 1: Get all data and if incremental get the new records
with source as (
    select * from {{ source('bronze_customer', 'customer_details') }}
    {% if is_incremental() %}
    where customer_id NOT IN (select customer_id from {{ this }})
    {% endif %}
),
-- Step 2: Run only if model is incremental
{% if is_incremental() %}
-- Get all records from current dimension
existing_data as (
    select * from {{ this }}
),
-- Get changed records by inner joining current dim table and bronze table where values have changes for a customer_id
changed_records as (
    select 
    s.customer_id,
    s.customer_name,
    s.gender,
    s.birth_date,
    s.email_add,
    s.country,
    s.zip_code,
    s.street,
    s.street_number,
    'Active' as status
    from {{ source ('bronze_customer','customer_details')}} s
    inner join 
    existing_data e
    on 
    s.customer_id = e.customer_id
    where
    s.customer_name <> e.customer_name or
    s.brith_date <> e.birth_date or
    s.email_address <> e.email_address

),
inactive_old_records as(
     select 
     e.customer_id,
     e.customer_name,
     e.gender,
     e.birth_date,
     e.email_address,
     e.country,
     e.zip_code,
     e.street,
     e.street_number,
     'Inactive 'as status
     from existing_data e
     inner join 
     changed_record c
     on 
     e.customer_id = c.customer_id
),
{% endif %}

-- Combine new records, changed record marked as active and old records marked as inactive

final_data as (
    select 
    customer_id,
    customer_name,
    gender,
    birth_date,
    email_address,
    country,
    zip_code,
    street,
    street_number,
    'Active' as status
    from 
    source
    {% if is_incremental() %}
    union all
    select 
    customer_id,
    customer_name,
    gender,
    birth_date,
    email_address,
    country,
    zip_code,
    street,
    streer_number,
    status 
    from inactive_old_records
    union all
    select 
      customer_id,
        customer_name,
        gender,
        birth_date,
        email_address,
        country,
        zip_code,
        street,
        street_number,
        status
    from changed_records
    {% endif %}
)
select 
 customer_id,
    customer_name,
    gender,
    birth_date,
    email_address,
    country,
    zip_code,
    street,
    street_number,
    status
from 
    final_data