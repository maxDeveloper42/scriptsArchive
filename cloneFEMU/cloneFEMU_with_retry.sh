#!/bin/bash

REPO_URL="https://github.com/maxDeveloper42/FEMU.git"
TARGET_DIR="FEMU"
MAX_RETRIES=0          # 0 = infinite retries
RETRY_DELAY=10         # seconds between retries
DEPTH=1

attempt=0

# Remove any partial clone so git doesn't refuse to clone into an existing dir
cleanup() {
    if [ -d "$TARGET_DIR" ] && [ ! -d "$TARGET_DIR/.git" ]; then
        echo ">>> Removing partial clone at $TARGET_DIR"
        rm -rf "$TARGET_DIR"
    fi
}

while true; do
    attempt=$((attempt + 1))
    echo
    echo "=========================================="
    echo "Attempt #$attempt  ($(date '+%Y-%m-%d %H:%M:%S'))"
    echo "=========================================="

    cleanup

    if git clone --depth=$DEPTH "$REPO_URL" "$TARGET_DIR"; then
        echo
        echo ">>> SUCCESS: cloned $REPO_URL into $TARGET_DIR"
        exit 0
    fi

    echo ">>> Clone failed. Retrying in ${RETRY_DELAY}s..."
    sleep $RETRY_DELAY

    if [ "$MAX_RETRIES" -gt 0 ] && [ "$attempt" -ge "$MAX_RETRIES" ]; then
        echo ">>> Reached max retries ($MAX_RETRIES). Giving up."
        exit 1
    fi
done
