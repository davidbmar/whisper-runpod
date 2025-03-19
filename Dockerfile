FROM fedirz/faster-whisper-server:latest-cuda
# Set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive
# Update and install essential packages including SSH server
RUN apt-get update && \
    apt-get install -y git vim python3 python3-pip sudo curl wget unzip openssh-server net-tools && \
    mkdir -p /var/run/sshd
# Create a symlink from python3 to python (CRITICAL FIX)
RUN ln -sf /usr/bin/python3 /usr/bin/python
# Install AWS CLI via pip
RUN pip3 install awscli
# Install boto, boto3, and pytubefix
RUN pip3 install boto boto3 pytubefix
# Install WhisperX
RUN pip3 install git+https://github.com/m-bain/whisperx.git
# Install ffmpeg
RUN apt-get install -y ffmpeg

# Install Node.js using nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    nvm install --lts && \
    nvm use --lts && \
    # Add nvm to bash profile for persistence
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc

# Add node and npm to PATH
ENV PATH="/root/.nvm/versions/node/$(ls -t /root/.nvm/versions/node/ | head -1)/bin:${PATH}"

# Clean up apt cache to reduce image size
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# Ensure SSH is properly configured for RunPod
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Create an entrypoint script that clones the repo, checks out master, and runs the script
RUN echo '#!/bin/bash\n\
# Define log file\n\
LOG_FILE="/app/startup_log.txt"\n\
echo "Container startup: $(date)" > $LOG_FILE\n\
\n\
# Start SSH service\n\
echo "Starting SSH service..." >> $LOG_FILE\n\
service ssh start && echo "SSH service started successfully" >> $LOG_FILE\n\
\n\
# Ensure nvm is available\n\
export NVM_DIR="$HOME/.nvm"\n\
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"\n\
\n\
# Verify Node.js installation\n\
node -v >> $LOG_FILE 2>&1\n\
npm -v >> $LOG_FILE 2>&1\n\
\n\
# Clone the repository\n\
echo "Cloning repository..." >> $LOG_FILE\n\
git clone https://github.com/davidbmar/youtube_commercial_detector.git /app/youtube_commercial_detector && echo "Repository cloned successfully" >> $LOG_FILE\n\
\n\
# Go into the repo directory\n\
cd /app/youtube_commercial_detector && echo "Changed directory to repo" >> $LOG_FILE\n\
\n\
# Checkout the master branch\n\
echo "Checking out master branch..." >> $LOG_FILE\n\
git checkout master && echo "Master branch checked out successfully" >> $LOG_FILE\n\
\n\
# Navigate to the step2-sqs-s3-download directory\n\
cd step2-sqs-s3-download && echo "Changed to step2-sqs-s3-download directory" >> $LOG_FILE\n\
\n\
# Run the script with the specified parameters\n\
echo "Starting scan-sqs-s3.py script..." >> $LOG_FILE\n\
python scan-sqs-s3.py \\\n\
  --queue_url https://sqs.us-east-2.amazonaws.com/635071011057/2025-03-15-youtube-transcription-queue \\\n\
  --phrase "flea markets" \\\n\
  --region us-east-2 > /app/script_output.log 2>&1 &\n\
\n\
# Save the PID of the script\n\
SCRIPT_PID=$!\n\
echo "Script started with PID: $SCRIPT_PID" >> $LOG_FILE\n\
\n\
# Check if script is running after a few seconds\n\
sleep 5\n\
if ps -p $SCRIPT_PID > /dev/null; then\n\
  echo "Script is running successfully as of $(date)" >> $LOG_FILE\n\
else\n\
  echo "ERROR: Script failed to start or exited quickly" >> $LOG_FILE\n\
  # Capture any error output\n\
  echo "Last few lines of script output:" >> $LOG_FILE\n\
  tail -n 20 /app/script_output.log >> $LOG_FILE\n\
fi\n\
\n\
echo "Startup process completed at $(date)" >> $LOG_FILE\n\
\n\
# Keep the container running\n\
while true; do\n\
  # Check if script is still running every 5 minutes and log status\n\
  if ! ps -p $SCRIPT_PID > /dev/null; then\n\
    echo "WARNING: Script process ($SCRIPT_PID) no longer running at $(date)" >> $LOG_FILE\n\
    echo "Last 50 lines of script output:" >> $LOG_FILE\n\
    tail -n 50 /app/script_output.log >> $LOG_FILE\n\
  fi\n\
  sleep 300\n\
done' > /entrypoint.sh && \
    chmod +x /entrypoint.sh
# Expose SSH port
EXPOSE 22
# Set working directory
WORKDIR /app
# Use the entrypoint script
CMD ["/entrypoint.sh"]
