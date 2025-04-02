# Faster Whisper Transcription Service

A containerized solution for running an automated speech-to-text transcription service using Faster Whisper.

## What This Project Does

This project provides:
- A Docker container running a Faster Whisper transcription server
- Scripts for downloading audio files from AWS S3
- Tools to automatically transcribe audio files
- Monitoring to ensure the service stays running

## Quick Start

1. **Build and push the Docker image:**
   ```bash
   docker build -t yourusername/whisper-runpod:latest .
   docker push yourusername/whisper-runpod:latest
   ```

2. **Deploy on RunPod.io:**
   - Create a new pod using this Docker image URL
   - The transcription API will be available on port 8000

3. **Use the transcription service:**
   - To transcribe a local file:
     ```bash
     curl http://localhost:8000/v1/audio/transcriptions \
          -F "file=@your-audio-file.mp3" \
          -F "language=en"
     ```
   
   - To download from S3 and transcribe:
     ```bash
     ./test_transcribe_by_fasterWhisperAPI_fromS3.sh my-bucket users/recordings audio-file.webm
     ./test_transcribe_by_fasterWhisperAPI_fromS3.sh bucket-name path/to/file.mp3
     ```

Here are some examples of how to use the test_transcribe_by_fasterWhisperAPI_fromS3.sh script based on the original code paths:
Example 1: Using the default values (same as original script)
./test_transcribe_by_fasterWhisperAPI_fromS3.sh
This will use:

Bucket: 2024-09-23-audiotranscribe-input-bucket
Path: users/customer/cognito/019be580-a0f1-705f-2a26-07443f1c5ad5
File: 2025-01-12-06-44-10-421662.webm
Language: en

Example 2: Specifying just the bucket name
./test_transcribe_by_fasterWhisperAPI_fromS3.sh 2024-09-23-audiotranscribe-input-bucket
This will use:

Bucket: 2024-09-23-audiotranscribe-input-bucket (specified)
Path: users/customer/cognito/019be580-a0f1-705f-2a26-07443f1c5ad5 (default)
File: 2025-01-12-06-44-10-421662.webm (default)
Language: en (default)

Example 3: Specifying bucket and path
./test_transcribe_by_fasterWhisperAPI_fromS3.sh 2024-09-23-audiotranscribe-input-bucket users/customer/cognito/019be580-a0f1-705f-2a26-07443f1c5ad5

Example 4: Specifying different filename but same bucket and path
./test_transcribe_by_fasterWhisperAPI_fromS3.sh 2024-09-23-audiotranscribe-input-bucket users/customer/cognito/019be580-a0f1-705f-2a26-07443f1c5ad5 new-recording.webm



## Components

- `entrypoint.sh` - Container startup script that launches the Whisper server and monitors it
- `test_transcribe_by_fasterWhisperAPI_fromS3.sh` - Script to download audio from S3 and transcribe it
- `Dockerfile` - Defines the container with all necessary dependencies

## Prerequisites

- Docker for building and testing locally
- AWS credentials configured for S3 access
- RunPod.io account (optional, for cloud deployment)

## How It Works

1. When the container starts, `entrypoint.sh` launches the Faster Whisper server
2. The server exposes an API on port 8000
3. You can either:
   - Send audio files directly to the API
   - Use the provided scripts to fetch from S3 and process automatically

## Troubleshooting

- If the service isn't responding, check container logs with `docker logs <container-id>`
- Verify AWS credentials are properly configured if using S3 integration
- Ensure the audio file format is supported (.mp3, .wav, .webm, etc.)
### Download from S3 and transcribe:

```bash
# Download from S3
aws s3 cp "s3://your-bucket/path/to/audio.mp3" .

# Transcribe
curl http://localhost:8000/v1/audio/transcriptions \
     -F "file=@audio.mp3" \
     -F "language=en"
```
