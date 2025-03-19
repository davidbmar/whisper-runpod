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
# Install boto and boto3
RUN pip3 install boto boto3
# Install ffmpeg
RUN apt-get install -y ffmpeg
# Clean up apt cache to reduce image size
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# Ensure SSH is properly configured for RunPod
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Create an entrypoint script that clones the repo, checks out master, and runs the script
RUN echo '#!/bin/bash\n\
# Start SSH service\n\
service ssh start\n\
\n\
# Clone the repository\n\
git clone https://github.com/davidbmar/youtube_commercial_detector.git /app/youtube_commercial_detector\n\
\n\
# Go into the repo directory\n\
cd /app/youtube_commercial_detector\n\
\n\
# Checkout the master branch\n\
git checkout master\n\
\n\
# Navigate to the step2-sqs-s3-download directory\n\
cd step2-sqs-s3-download\n\
\n\
# Run the script with the specified parameters in the background\n\
python scan-sqs-s3.py \\\n\
  --queue_url https://sqs.us-east-2.amazonaws.com/635071011057/2025-03-15-youtube-transcription-queue \\\n\
  --phrase "flea markets" \\\n\
  --region us-east-2 &\n\
\n\
# Keep the container running\n\
while true; do sleep 30; done' > /entrypoint.sh && \
    chmod +x /entrypoint.sh
# Expose SSH port
EXPOSE 22
# Set working directory
WORKDIR /app
# Use the entrypoint script
CMD ["/entrypoint.sh"]
