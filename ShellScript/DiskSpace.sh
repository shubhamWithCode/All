#!/bin/bash

# Set threshold (in percent)
THRESHOLD=80

# Get disk usage of root (/)
USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Show usage
echo "Disk usage is at ${USAGE}%"

# Check if it’s too high
if [ "$USAGE" -ge "$THRESHOLD" ]; then
    echo "WARNING: Disk usage is above ${THRESHOLD}%!"
else
    echo "Disk usage is normal."
fi
