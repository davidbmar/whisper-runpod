#!/bin/bash
set -e

# Create python symlink if it doesn't exist
if ! command -v python &> /dev/null && command -v python3 &> /dev/null; then
    echo "Creating symlink from python3 to python..."
    ln -sf /usr/bin/python3 /usr/bin/python
fi

# Verify python is now available
if ! command -v python &> /dev/null; then
    echo "ERROR: Python is still not available. Trying to use python3 directly."
    PYTHON_CMD="python3"
else
    PYTHON_CMD="python"
fi

echo "Starting Faster Whisper Server..."

# Start the Faster Whisper server in the background
$PYTHON_CMD -m faster_whisper.server.app &

# Store the PID of the server
SERVER_PID=$!

echo "Faster Whisper Server started with PID: $SERVER_PID"
echo "Container is now running. Use CTRL+C to stop."

# Keep the container running
while true; do
  # Check if the server process is still running
  if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "Faster Whisper Server has stopped unexpectedly. Restarting..."
    $PYTHON_CMD -m faster_whisper.server.app &
    SERVER_PID=$!
    echo "Restarted with PID: $SERVER_PID"
  fi
  
  # Sleep for a while before checking again
  sleep 10
done
