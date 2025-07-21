#!/bin/bash
# Configuration
LOG_DIR="/var/log/myapp"
LOG_FILE="app.log"
MAX_LOGS=5
OWNER="appuser"
PERMISSIONS="644"

cd "$LOG_DIR" || exit 1

# Step 1: Delete older logs
for (( i=MAX_LOGS; i<=20; i++ )); do
    [ -f "${LOG_FILE}.${i}" ] && rm -f "${LOG_FILE}.${i}"
done

# Step 2: Rotate logs from highest to lowest
for (( i=MAX_LOGS-1; i>=1; i-- )); do
    if [ -f "${LOG_FILE}.${i}" ]; then
        mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i+1))"
    fi
done

# Step 3: Rename app.log to app.log.1 if it exists
if [ -f "$LOG_FILE" ]; then
    mv "$LOG_FILE" "${LOG_FILE}.1"
fi

# Step 4: Create a new empty app.log with correct owner and permissions
touch "$LOG_FILE"
chown "$OWNER":"$OWNER" "$LOG_FILE"
chmod "$PERMISSIONS" "$LOG_FILE"

echo "Log rotation complete."
