#!/bin/bash

# Output file with date and time in the filename
OUTPUT_FILE="/var/lib/postgresql/miracle_online/script/log/postgresql_report_$(date '+%Y-%m-%d_%H-%M-%S').txt"

PG_TEST_FSYNC_FILE="/var/lib/postgresql/miracle_online/script/log/pg_test_fsync.out"

# Log file path
LOG_FILE_PATH="/var/log/postgresql"

# Backup directory path
BACKUP_DIR="/var/log/postgresql/backup"

# PostgreSQL Version
echo -e "\n--- PostgreSQL Version ---" >> $OUTPUT_FILE
psql -U postgres -c "SELECT version();" >> $OUTPUT_FILE

# Filesystem usage (like df -h)
echo -e "\n--- Filesystem Usage (df -h -T) ---" >> $OUTPUT_FILE
df -h -T >> $OUTPUT_FILE

# CPU load
echo -e "\n--- CPU Load ---" >> $OUTPUT_FILE
uptime >> $OUTPUT_FILE

# Memory usage
echo -e "\n--- Memory Usage ---" >> $OUTPUT_FILE
free -h >> $OUTPUT_FILE

# PostgreSQL Information
echo -e "\n--- PostgreSQL Information ---" >> $OUTPUT_FILE

# Database startup time
echo -e "\nDatabase Startup Time:" >> $OUTPUT_FILE
psql -U postgres -c "SELECT pg_postmaster_start_time();" >> $OUTPUT_FILE

# Size of tablespaces
echo -e "\nTablespace Sizes:" >> $OUTPUT_FILE
psql -U postgres -c "SELECT spcname as tablespace_name, pg_size_pretty(pg_tablespace_size(oid)) as size FROM pg_tablespace;" >> $OUTPUT_FILE

# Database names with sizes in KB and MB
echo -e "\nDatabase Names with Sizes:" >> $OUTPUT_FILE
psql -U postgres -c "SELECT datname AS database_name, pg_database_size(datname) AS size_in_kb, pg_size_pretty(pg_database_size(datname)) AS size_in_mb FROM pg_database;" >> $OUTPUT_FILE

# Last 10 WAL files
echo -e "\nLast 10 WAL Files:" >> $OUTPUT_FILE
psql -U postgres -c "SELECT * FROM pg_ls_waldir() ORDER BY modification DESC LIMIT 10;" >> $OUTPUT_FILE

# Check if the database is in backup mode
echo -e "\nIs Database in Backup Mode?" >> $OUTPUT_FILE
psql -U postgres -c "SELECT pg_is_in_backup() as is_in_backup;" >> $OUTPUT_FILE

# List of users
echo -e "\nList of Users:" >> $OUTPUT_FILE
psql -U postgres -c "SELECT usename FROM pg_user;" >> $OUTPUT_FILE

# CPU-hogging processes in PostgreSQL
echo -e "\nTop 10 CPU-hogging Processes in PostgreSQL:" >> $OUTPUT_FILE
psql -U postgres -c "\x on" -c "SELECT pid, usename, application_name, client_addr, backend_start, state, state_change, LEFT(query, 100) AS query_excerpt FROM pg_stat_activity ORDER BY (extract(epoch FROM now()) - extract(epoch FROM query_start)) DESC LIMIT 10;" >> $OUTPUT_FILE

# Memory settings in PostgreSQL
echo -e "\nPostgreSQL Memory Usage Settings:" >> $OUTPUT_FILE
psql -U postgres -c "SELECT name, setting, unit FROM pg_settings WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem', 'effective_cache_size', 'wal_buffers', 'effective_io_concurrency', 'min_wal_size', 'max_wal_size', 'max_worker_processes', 'max_parallel_workers_per_gather', 'max_parallel_workers', 'max_parallel_maintenance_workers', 'huge_pages', 'random_page_cost', 'default_statistics_target', 'checkpoint_completion_target', 'max_connections');" >> $OUTPUT_FILE

# Backup checks
echo -e "\n--- Backup Check (Last 30 Days) ---" >> $OUTPUT_FILE

# pg_test_fsync for best sync method
echo -e "\npg_test_fsync for best sync method"
pg_test_fsync -f PG_TEST_FSYNC_FILE >> $OUTPUT_FILE

# Find log files modified in the last 30 days and check for errors
find $BACKUP_DIR -type f -mtime -30 | while read log_file; do
    # Check for errors in the last 30 lines of the log file
    error_lines=$(tail -n 30 "$log_file" | grep -i "error")

    if [ -n "$error_lines" ]; then
        echo -e "\nErrors found in $log_file:" >> $OUTPUT_FILE
        echo "$error_lines" >> $OUTPUT_FILE
    fi
done

# Check for errors in PostgreSQL log files
echo -e "\n--- PostgreSQL Log Errors ---" >> $OUTPUT_FILE
if [ -d "$LOG_FILE_PATH" ]; then
    grep -i "ERROR" $LOG_FILE_PATH/*.log | tail -n 10 >> $OUTPUT_FILE
    echo -e "\nChecked PostgreSQL logs for errors, displaying last 10 entries if any found." >> $OUTPUT_FILE
else
    echo "Log file path not found or incorrect. Please verify the log file location." >> $OUTPUT_FILE
fi
