#!/bin/bash

# Name of the service to check
SERVICE="apache2"  # Change this to your service name, e.g., nginx, mysql, docker, etc.

# Check service status
if systemctl is-active --quiet "$SERVICE"; then
    echo "$SERVICE is running."
else
    echo "$SERVICE is NOT running. Starting it now..."
    sudo systemctl start "$SERVICE"

    # Check again to confirm it started
    if systemctl is-active --quiet "$SERVICE"; then
        echo "$SERVICE has been started successfully."
    else
        echo "Failed to start $SERVICE. Check logs or permissions."
    fi
fi
