FROM fedirz/faster-whisper-server:latest-cuda

# Set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install git, vim, and Python tools
RUN apt-get update && \
    apt-get install -y git vim python3 python3-pip

# Install curl, wget, and unzip
RUN apt-get install -y curl wget unzip

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Check which Python/pip is available and install packages
RUN which python || which python3 || apt-get install -y python3
RUN which pip || which pip3 || apt-get install -y python3-pip

# Install/upgrade pip and Python packages
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install faster-whisper boto3 requests pyyaml torch urllib3 botocore soundfile

# Install ffmpeg
RUN apt-get update && apt-get install -y ffmpeg

# Clean up apt cache to reduce image size
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy test script (if you have one)
COPY test_fastwhisperAPI.sh /app/test_fastwhisperAPI.sh
RUN chmod +x /app/test_fastwhisperAPI.sh

# Set working directory
WORKDIR /app

# Default command (can be overridden)
CMD ["python", "-m", "faster_whisper.server.app"]
