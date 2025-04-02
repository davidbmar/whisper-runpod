#!/bin/bash
#
# Faster Whisper Server Entrypoint
# --------------------------------
# This script starts the Faster Whisper server and keeps it running,
# restarting it if it crashes. It also configures required environment.
#
# The script will display status messages and logs to track server health.

set -e

# Colors for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log with timestamp
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${1}"
}

# Handle script termination
cleanup() {
    log "${YELLOW}Shutting down Faster Whisper Server...${NC}"
    if [ ! -z "$SERVER_PID" ]; then
        kill -TERM "$SERVER_PID" 2>/dev/null || true
    fi
    log "${GREEN}Shutdown complete.${NC}"
    exit 0
}

# Set up trap for graceful shutdown
trap cleanup SIGINT SIGTERM

# Check and configure Python
setup_python() {
    log "${YELLOW}Setting up Python environment...${NC}"
    
    # Create python symlink if needed
    if ! command -v python &> /dev/null && command -v python3 &> /dev/null; then
        log "Creating symlink from python3 to python..."
        ln -sf /usr/bin/python3 /usr/bin/python
    fi

    # Verify python is available
    if ! command -v python &> /dev/null; then
        log "${RED}WARNING: Python is not available as 'python'. Using 'python3' directly.${NC}"
        PYTHON_CMD="python3"
    else
        PYTHON_CMD="python"
        log "${GREEN}Python is configured correctly.${NC}"
    fi
    
    # Verify faster_whisper is installed
    if ! $PYTHON_CMD -c "import faster_whisper" &> /dev/null; then
        log "${RED}ERROR: faster_whisper package is not installed!${NC}"
        log "Please install it with: pip install faster-whisper"
        exit 1
    fi
}

# Start the Faster Whisper server
start_server() {
    log "${YELLOW}Starting Faster Whisper Server...${NC}"
    
    # Start server with output to log file
    $PYTHON_CMD -m faster_whisper.server.app > /var/log/whisper-server.log 2>&1 &
    SERVER_PID=$!
    
    # Verify server started
    if ! ps -p $SERVER_PID > /dev/null; then
        log "${RED}Failed to start server!${NC}"
        exit 1
    fi
    
    log "${GREEN}Server started with PID: ${SERVER_PID}${NC}"
    log "${BLUE}Waiting for server to initialize...${NC}"
    
    # Wait for server to be ready
    for i in {1..30}; do
        if curl -s "http://localhost:8000/health" | grep -q "healthy"; then
            log "${GREEN}Server is ready and healthy!${NC}"
            log "${BLUE}API is available at: http://localhost:8000${NC}"
            return 0
        fi
        sleep 1
    done
    
    log "${RED}Warning: Server didn't respond to health check within timeout.${NC}"
    log "${YELLOW}Continuing anyway - server might still be initializing...${NC}"
}

# Monitor server health and restart if needed
monitor_server() {
    log "${YELLOW}Starting server monitoring...${NC}"
    
    while true; do
        # Check if the server process is still running
        if ! kill -0 $SERVER_PID 2>/dev/null; then
            log "${RED}Faster Whisper Server has stopped unexpectedly. Restarting...${NC}"
            start_server
        fi
        
        # Optionally check server health API
        if ! curl -s "http://localhost:8000/health" | grep -q "healthy"; then
            log "${YELLOW}Health check failed. Server might be unresponsive.${NC}"
            
            # If server process exists but health check fails, restart it
            if kill -0 $SERVER_PID 2>/dev/null; then
                log "${YELLOW}Terminating unresponsive server (PID: ${SERVER_PID})${NC}"
                kill -TERM $SERVER_PID 2>/dev/null || true
                sleep 2
            fi
            
            log "${YELLOW}Restarting server...${NC}"
            start_server
        else
            log "${GREEN}Server health check: OK${NC}"
        fi
        
        # Display latest log entries
        log "${BLUE}Recent server activity:${NC}"
        tail -n 5 /var/log/whisper-server.log
        
        # Sleep for a while before checking again
        log "${BLUE}Next health check in 60 seconds...${NC}"
        sleep 60
    done
}

# Execute custom user scripts if present
run_custom_scripts() {
    CUSTOM_SCRIPTS_DIR="/opt/custom_scripts"
    
    if [ -d "$CUSTOM_SCRIPTS_DIR" ]; then
        log "${YELLOW}Looking for custom scripts in ${CUSTOM_SCRIPTS_DIR}...${NC}"
        
        # Find executable files
        SCRIPTS=$(find "$CUSTOM_SCRIPTS_DIR" -type f -executable | sort)
        
        if [ -z "$SCRIPTS" ]; then
            log "${BLUE}No custom scripts found.${NC}"
            return
        fi
        
        # Execute each script
        for script in $SCRIPTS; do
            log "${YELLOW}Executing custom script: $(basename "$script")${NC}"
            "$script" &
            log "${GREEN}Started: $(basename "$script") (PID: $!)${NC}"
        done
    fi
}

# Main function
main() {
    log "${GREEN}=== Initializing Faster Whisper Transcription Service ===${NC}"
    
    # Create log directory if it doesn't exist
    mkdir -p /var/log
    touch /var/log/whisper-server.log
    
    # Setup environment
    setup_python
    
    # Start the server
    start_server
    
    # Run any custom scripts
    run_custom_scripts
    
    # Print server info
    log "${GREEN}=== Faster Whisper Server is running ===${NC}"
    log "${BLUE}Server PID: ${SERVER_PID}${NC}"
    log "${BLUE}API Endpoint: http://localhost:8000/v1/audio/transcriptions${NC}"
    log "${BLUE}Health Check: http://localhost:8000/health${NC}"
    
    # Start monitoring
    monitor_server
}

# Run the main function
main
