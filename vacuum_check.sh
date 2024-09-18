#!/bin/bash

# Define the output file for the vacuum check
VACUUM_OUTPUT_FILE="/var/lib/postgresql/miracle_online/script/log/postgresql_vacuum_report_$(date '+%Y-%m-%d_%H-%M-%S').txt"

# Dead Tuples Check
echo -e "Vacuum Check Report generated on: $(date)" > $VACUUM_OUTPUT_FILE
echo -e "\n--- Dead Tuples Check for Vacuum ---" >> $VACUUM_OUTPUT_FILE

# Iterate over all databases
psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" | while read dbname; do
    echo -e "\nChecking database: $dbname" >> $VACUUM_OUTPUT_FILE
    psql -U postgres -d "$dbname" -c "
        SELECT
            relname AS table_name,
            n_dead_tup AS dead_tuples,
            pg_size_pretty(pg_total_relation_size(relid)) AS table_size
			(n_dead_tup * (pg_relation_size(relid) / GREATEST(n_live_tup + n_dead_tup, 1)) / (1024 * 1024)) AS est_dead_tup_size_mb
        FROM pg_stat_user_tables
        WHERE n_dead_tup > 0
        ORDER BY n_dead_tup DESC
        LIMIT 5;
    " >> $VACUUM_OUTPUT_FILE

    # If no rows are returned, log that no tables were found
    if [ $(tail -n 2 $VACUUM_OUTPUT_FILE | grep -c "(0 rows)") -ne 0 ]; then
        echo "No tables with dead tuples found in $dbname." >> $VACUUM_OUTPUT_FILE
    fi
done

echo -e "\nVacuum check completed. Report saved to $VACUUM_OUTPUT_FILE."
