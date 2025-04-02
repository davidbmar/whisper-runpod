#!/usr/bin/bash
#
# S3 Audio Transcription Tool
# ---------------------------
# Downloads an audio file from S3 and transcribes it using the Faster Whisper API.
#
# Usage:
#   ./transcribe_from_s3.sh [bucket] [path/to/file] [language]
#
# Example:
#   ./transcribe_from_s3.sh my-audio-bucket users/john/recording.webm en
#
# If no arguments are provided, default values will be used.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values (can be overridden with command line arguments)
DEFAULT_S3_BUCKET="2024-09-23-audiotranscribe-input-bucket"
DEFAULT_USER_PATH="users/customer/cognito/019be580-a0f1-705f-2a26-07443f1c5ad5"
DEFAULT_AUDIO_FILE="2025-01-12-06-44-10-421662.webm"
DEFAULT_LANGUAGE="en"

# Parse command line arguments
S3_BUCKET=${1:-$DEFAULT_S3_BUCKET}
USER_PATH=${2:-$DEFAULT_USER_PATH}
AUDIO_FILE=${3:-$DEFAULT_AUDIO_FILE}
LANGUAGE=${4:-$DEFAULT_LANGUAGE}

# API endpoint
TRANSCRIPTION_URL="http://localhost:8000/v1/audio/transcriptions"

# Log the start of the process with timestamp
log_message() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${1}"
}

# Check AWS credentials
check_aws_credentials() {
    log_message "${YELLOW}Checking AWS credentials...${NC}"
    
    if [ ! -f "${HOME}/.aws/credentials" ] || [ ! -s "${HOME}/.aws/credentials" ]; then
        log_message "${RED}Error: AWS credentials not found or empty.${NC}"
        log_message "${YELLOW}Please run 'aws configure' with your credentials:${NC}"
        echo "  - AWS Access Key ID"
        echo "  - AWS Secret Access Key"
        echo "  - Default region name (e.g., us-east-1)"
        echo "  - Default output format (json recommended)"
        exit 1
    fi

    log_message "${GREEN}AWS credentials verified.${NC}"
}

# Download file from S3
download_from_s3() {
    local s3_path="s3://${S3_BUCKET}/${USER_PATH}/${AUDIO_FILE}"
    local filename=$(basename "${AUDIO_FILE}")
    
    log_message "${YELLOW}Downloading: ${s3_path}${NC}"
    
    if aws s3 cp "${s3_path}" "./downloaded_${filename}"; then
        log_message "${GREEN}Download successful.${NC}"
        echo "./downloaded_${filename}" # Return the local file path
    else
        log_message "${RED}Error: Failed to download from S3!${NC}"
        exit 1
    fi
}

# Transcribe audio file
transcribe_audio() {
    local file_path=$1
    
    log_message "${YELLOW}Transcribing audio file: ${file_path}${NC}"
    log_message "Using language: ${LANGUAGE}"
    
    # Send file to transcription service
    response=$(curl -s "${TRANSCRIPTION_URL}" \
         -F "file=@${file_path}" \
         -F "language=${LANGUAGE}")
    
    if [ $? -eq 0 ]; then
        log_message "${GREEN}Transcription completed.${NC}"
        
        # Parse and display the transcription result
        echo ""
        echo "---- TRANSCRIPTION RESULT ----"
        echo "${response}" | grep -o '"text":"[^"]*"' | sed 's/"text":"//;s/"$//'
        echo "-----------------------------"
        echo ""
        
        # Save full response to file
        echo "${response}" > "transcription_result.json"
        log_message "${GREEN}Full response saved to transcription_result.json${NC}"
    else
        log_message "${RED}Error: Transcription request failed!${NC}"
        exit 1
    fi
}

# Clean up downloaded files
cleanup() {
    log_message "${YELLOW}Cleaning up temporary files...${NC}"
    rm -f "${1}"
    log_message "${GREEN}Cleanup complete.${NC}"
}

# Main execution
main() {
    log_message "${YELLOW}=== Starting Audio Transcription Process ===${NC}"
    
    # Show the configuration
    echo "Configuration:"
    echo "  S3 Bucket: ${S3_BUCKET}"
    echo "  Path: ${USER_PATH}"
    echo "  File: ${AUDIO_FILE}"
    echo "  Language: ${LANGUAGE}"
    echo ""
    
    # Run the process
    check_aws_credentials
    local local_file=$(download_from_s3)
    transcribe_audio "${local_file}"
    cleanup "${local_file}"
    
    log_message "${GREEN}=== Process completed successfully ===${NC}"
}

# Run the main function
main
