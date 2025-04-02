# Faster Whisper Transcription Service
# Based on fedirz/faster-whisper-server with additional tools

FROM fedirz/faster-whisper-server:latest-cuda

LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Enhanced Faster Whisper server with S3 integration and monitoring"
LABEL version="1.0"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    wget \
    unzip \
    ffmpeg \
    python3-pip \
    jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    boto3 \
    requests \
    pyyaml \
    faster-whisper \
    torch \
    urllib3 \
    botocore \
    soundfile

# Create directories
RUN mkdir -p /app /opt/custom_scripts /var/log

# Copy application files
COPY entrypoint.sh /app/
COPY transcribe_from_s3.sh /app/

# Make scripts executable
RUN chmod +x /app/entrypoint.sh /app/transcribe_from_s3.sh

# Create a symbolic link to make scripts available in PATH
RUN ln -sf /app/transcribe_from_s3.sh /usr/local/bin/transcribe_from_s3

# Set up custom scripts directory for user scripts
RUN echo '#!/bin/bash\necho "This is a sample custom script that runs on container startup"\necho "Replace this with your own scripts by mounting a volume to /opt/custom_scripts"' > /opt/custom_scripts/example.sh \
    && chmod +x /opt/custom_scripts/example.sh

# Expose the API port
EXPOSE 8000

# Set working directory
WORKDIR /app

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
