    #!/bin/bash

    # Navigate to the dbt project directory
    cd "C:/Users/user/.snowflake/dbt_core/scripts/dbt_dwh" || exit

    # Run Silver Layer with target 'dev'
    dbt run --select path:models/Silver_layer --target dev >> logs/dbt_silver.log 2>&1

    # Run Bronze Layer with target 'prod'
    dbt run --select path:models/golden_layer --target prod >> logs/dbt_bronze.log 2>&1
