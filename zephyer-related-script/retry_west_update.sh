#!/bin/bash

# Configuration
MAX_RETRIES=1000
RETRY_DELAY=60          # seconds between attempts
WEST_DIR="/home/ubuntu/zephyrproject/zephyr"
LOG_FILE="$HOME/west_update_retry.log"

# The exact west command you used
WEST_CMD="west update --group-filter=\"-babblesim,-optional,-testing,-fs,-crypto,-bootloader,-debug,-tools,-tee\""

# Change to the Zephyr directory
cd "$WEST_DIR" || {
    echo "ERROR: Cannot cd to $WEST_DIR" | tee -a "$LOG_FILE"
    exit 1
}

# Start logging
echo "=== West update retry script started at $(date) ===" >> "$LOG_FILE"
echo "Max retries: $MAX_RETRIES, delay: $RETRY_DELAY s" >> "$LOG_FILE"

for ((attempt=1; attempt<=MAX_RETRIES; attempt++)); do
    echo "Attempt $attempt of $MAX_RETRIES ..." | tee -a "$LOG_FILE"

    # Run west update, capture output and exit code
    eval "$WEST_CMD" >> "$LOG_FILE" 2>&1
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "SUCCESS: West update completed at $(date)" | tee -a "$LOG_FILE"
        exit 0
    fi

    echo "Attempt $attempt failed (exit code $exit_code). Waiting $RETRY_DELAY seconds..." | tee -a "$LOG_FILE"
    sleep "$RETRY_DELAY"
done

echo "FAILURE: West update did not succeed after $MAX_RETRIES attempts." | tee -a "$LOG_FILE"
exit 1
