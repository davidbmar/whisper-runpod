# Custom Faster Whisper Docker Image

This Docker image extends `fedirz/faster-whisper-server:latest-cuda` with additional tools and dependencies:

- Git and vim for development
- AWS CLI v2 for S3 integration
- Python packages:
  - boto3
  - requests
  - pyyaml
  - faster-whisper
  - torch
  - urllib3
  - botocore
  - soundfile
- ffmpeg for audio processing

## Usage on RunPod.io

1. When creating a new pod on RunPod.io, use the custom Docker image URL
2. The Faster Whisper API will be available on port 8000

## API Examples

### Transcribe an audio file:

```bash
curl http://localhost:8000/v1/audio/transcriptions \
     -F "file=@audio.mp3" \
     -F "language=en"
```

### Download from S3 and transcribe:

```bash
# Download from S3
aws s3 cp "s3://your-bucket/path/to/audio.mp3" .

# Transcribe
curl http://localhost:8000/v1/audio/transcriptions \
     -F "file=@audio.mp3" \
     -F "language=en"
```
