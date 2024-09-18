#!/bin/bash

# PostgreSQL home directory (read from environment)
PG_HOME=${PG_HOME:-/var/lib/postgresql}

# Output file located in
OUTPUT_FILE="/var/lib/postgresql/miracle_online/script/log/postgresql_report_$(date '+%Y-%m-%d_%H-%M-%S').txt"

# Basic system and database info
/bin/bash /var/lib/postgresql/miracle_online/script/head_check.sh $OUTPUT_FILE

#vacuum check for tables with dead tuples for the 10 highest values.
/bin/bash /var/lib/postgresql/miracle_online/script/vacuum_check.sh $OUTPUT_FILE

# Final message
echo "All checks completed. Report saved to $OUTPUT_FILE."
