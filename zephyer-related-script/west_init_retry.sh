#!/bin/bash

# west_init_retry.sh - Script to retry west init with nohup

# Configuration
MAX_RETRIES=90000
RETRY_DELAY=30  # seconds between retries
WEST_MANIFEST_URL="https://github.com/zephyrproject-rtos/zephyr"
WEST_PROJECT_DIR="${HOME}/zephyrproject"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to cleanup .west directory
cleanup_west() {
    local west_dir="${WEST_PROJECT_DIR}/.west"
    if [ -d "$west_dir" ]; then
        log_info "Removing existing .west directory..."
        rm -rf "$west_dir"
        if [ $? -eq 0 ]; then
            log_info ".west directory removed successfully"
        else
            log_error "Failed to remove .west directory"
            return 1
        fi
    else
        log_info "No .west directory found to remove"
    fi
    return 0
}

# Function to run west init
run_west_init() {
    local attempt=$1
    local log_file="${WEST_PROJECT_DIR}/west_init_attempt_${attempt}.log"
    
    log_info "Attempt $attempt: Running west init..."
    log_info "Log file: $log_file"
    
    # Run west init with nohup
    nohup west init -m "$WEST_MANIFEST_URL" "$WEST_PROJECT_DIR" > "$log_file" 2>&1
    
    # Capture the exit code
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_info "west init completed successfully on attempt $attempt!"
        return 0
    else
        log_error "west init failed on attempt $attempt (exit code: $exit_code)"
        log_info "Last few lines of log:"
        tail -n 10 "$log_file"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting west init retry script..."
    log_info "Working directory: ${WEST_PROJECT_DIR}"
    log_info "Max retries: ${MAX_RETRIES}"
    log_info "Retry delay: ${RETRY_DELAY} seconds"
    echo ""
    
    # Create project directory if it doesn't exist
    if [ ! -d "$WEST_PROJECT_DIR" ]; then
        log_info "Creating project directory: ${WEST_PROJECT_DIR}"
        mkdir -p "$WEST_PROJECT_DIR"
        if [ $? -ne 0 ]; then
            log_error "Failed to create project directory"
            exit 1
        fi
    fi
    
    # Change to project directory
    cd "$WEST_PROJECT_DIR" || exit 1
    
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        log_info "=== Attempt $attempt of $MAX_RETRIES ==="
        
        # Cleanup .west directory
        cleanup_west
        if [ $? -ne 0 ]; then
            log_warning "Cleanup failed, continuing anyway..."
        fi
        
        # Run west init
        if run_west_init $attempt; then
            log_info "west init completed successfully!"
            exit 0
        fi
        
        # If this was the last attempt, exit with failure
        if [ $attempt -eq $MAX_RETRIES ]; then
            log_error "All $MAX_RETRIES attempts failed. Please check the logs."
            exit 1
        fi
        
        # Wait before retry
        log_info "Waiting ${RETRY_DELAY} seconds before retry..."
        sleep $RETRY_DELAY
        
        ((attempt++))
    done
}

# Trap Ctrl+C
trap 'echo -e "\n${YELLOW}Script interrupted by user${NC}"; exit 1' INT

# Run main function
main
