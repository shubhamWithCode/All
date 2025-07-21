#!/bin/bash

# Set the directory path
TARGET_DIR="/path/to/your/directory"

# Delete files older than 7 days
find "$TARGET_DIR" -type f -mtime +7 -exec rm -f {} \;

echo "Deleted files older than 7 days from $TARGET_DIR"
