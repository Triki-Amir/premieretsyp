# Construction Worker Safety Detection

A Python project that uses YOLO (via the ultralytics package) to detect helmets and reflective jackets and provide real-time safety monitoring. This repo contains three ways to run detection:

- **CLI Script** (`safety_detection.py`) - Single-file, webcam/RTSP detection
- **Pi Camera Stream** (`stream_detection.py`) - Connects to Raspberry Pi camera via RTSP
- **Web UI** (`app.py`) - Flask-powered web interface with video streaming

## Quick Start

### 1. Install Dependencies

Create and activate a virtual environment:

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/macOS
source venv/bin/activate
```

Install required packages:

```bash
pip install ultralytics opencv-python flask numpy requests torch
```

### 2. Usage Options

#### Option A: Local Webcam Detection (Simple CLI)

```bash
python safety_detection.py
```

Press `q` to quit. Edit the script to change `MODEL_PATH`, `VIDEO_SOURCE`, or webhook URLs.

---

#### Option B: Raspberry Pi Camera Stream (Recommended for Remote Camera)

**Step 1: On Raspberry Pi** - Set up and start the camera stream

```bash
# Install MediaMTX
wget https://github.com/bluenviron/mediamtx/releases/download/v1.9.0/mediamtx_v1.9.0_linux_arm64v8.tar.gz
tar -xzf mediamtx_v1.9.0_linux_arm64v8.tar.gz

# Create config file
nano mediamtx.yml
```

Add this configuration:

```yaml
paths:
  cam:
    source: rpiCamera
    rpiCameraWidth: 640
    rpiCameraHeight: 480
    rpiCameraFPS: 25
```

Start the stream:

```bash
./mediamtx
```

**Step 2: On Your PC** - Connect and run detection

```bash
# Basic usage (replace with your Pi's IP address)
python stream_detection.py --pi-ip 192.168.137.211 --model best2.pt

# With GPU acceleration
python stream_detection.py --pi-ip 192.168.137.211 --model best2.pt --device cuda

# Save video output
python stream_detection.py --pi-ip 192.168.137.211 --model best2.pt --save-video

# Run without display (headless)
python stream_detection.py --pi-ip 192.168.137.211 --model best2.pt --no-display --save-video
```

**Keyboard Controls:**
- Press `q` to quit
- Press `s` to save screenshot

**Available Options:**
- `--pi-ip` - Raspberry Pi IP address (required)
- `--model` - Path to YOLO model (default: best.pt)
- `--device` - Use 'cuda' for GPU or 'cpu' (default: cpu)
- `--conf` - Confidence threshold (default: 0.5)
- `--save-video` - Save annotated output video
- `--no-display` - Run without display window
- `--protocol` - Stream protocol: rtsp, http, tcp, udp (default: rtsp)
- `--port` - Stream port (default: 8554)
- `--path` - RTSP stream path (default: cam)

---

#### Option C: Web UI (Browser-Based Interface)

**With Local Webcam:**

```bash
python app.py
```

**With Raspberry Pi Camera:**

First, make sure MediaMTX is running on your Pi (see Option B, Step 1), then:

```bash
# Basic usage
python app.py --pi-ip 192.168.137.211

# Custom port
python app.py --pi-ip 192.168.137.211 --port 8080

# Different stream path
python app.py --pi-ip 192.168.137.211 --pi-path stream
```

Open your browser and go to: `http://localhost:5000` (or your custom port)

**Web UI Options:**
- `--pi-ip` - Raspberry Pi IP address (omit to use local webcam)
- `--pi-port` - RTSP port (default: 8554)
- `--pi-path` - RTSP stream path (default: cam)
- `--local-camera` - Local camera index (default: 0)
- `--host` - Flask host (default: 0.0.0.0)
- `--port` - Flask port (default: 5000)

---

## Complete Raspberry Pi Setup Guide

For detailed instructions on setting up your Raspberry Pi camera, troubleshooting, and advanced configurations, see **[PI_CAMERA_SETUP.md](PI_CAMERA_SETUP.md)**.

## Model Files

The repository uses these model files:

- `best2.pt` - Main PPE detection model (helmets and jackets)
- `best-2.pt` - Optional person detection model (used by `app.py`)

Place your trained YOLO models in the repo root, or specify a custom path with `--model`.

## Configuration

### safety_detection.py
Edit these variables at the top of the file:
- `MODEL_PATH` - YOLO model path (default: `best2.pt`)
- `VIDEO_SOURCE` - 0 for webcam, or RTSP URL
- `NOTIFICATION_WEBHOOK_URL` - Webhook for safe status
- `ALERT_WEBHOOK_URL` - Webhook for safety violations
- `CONFIDENCE_THRESHOLD` - Detection threshold (default: 0.5)

### stream_detection.py
Use command-line arguments (see Option B above)

### app.py
Use command-line arguments (see Option C above)

## Webhook Payloads

Notification (safe worker):
```json
{
  "type": "safety_compliance",
  "status": "SAFE",
  "message": "Worker is wearing proper safety equipment (helmet and jacket)",
  "timestamp": "2025-11-23 10:30:45"
}
```

Alert (safety violation):
```json
{
  "type": "safety_violation",
  "status": "UNSAFE",
  "message": "ALERT: Missing safety gear - helmet",
  "timestamp": "2025-11-23 10:31:22"
}
```

## Troubleshooting

**Cannot connect to Pi camera stream:**
1. Check Pi IP address: `hostname -I` on Pi
2. Verify MediaMTX is running: Look for "listener opened on :8554"
3. Test with VLC: Open `rtsp://<PI_IP>:8554/cam`
4. Check firewall/network settings

**Model not found:**
- Ensure model file exists in the project directory
- Use `--model` to specify correct path

**Low FPS/Lag:**
- Lower resolution in `mediamtx.yml`
- Use Ethernet instead of Wi-Fi
- Use GPU: `--device cuda`

**No detections:**
- Check confidence threshold: `--conf 0.3`
- Verify model is trained for helmet/jacket detection
- Ensure good lighting

## Project Files

- `safety_detection.py` - CLI detection with local/RTSP camera
- `stream_detection.py` - Pi camera stream detection
- `app.py` - Flask web UI with video feed
- `templates/index.html` - Web UI template
- `PI_CAMERA_SETUP.md` - Complete Pi camera setup guide
- `best2.pt`, `best-2.pt` - YOLO model weights

## Example Workflows

**Development/Testing:**
```bash
# Use local webcam
python safety_detection.py
```

**Production with Pi Camera:**
```bash
# On Raspberry Pi
./mediamtx

# On PC (display mode)
python stream_detection.py --pi-ip 192.168.137.211 --model best2.pt --device cuda

# On PC (headless server mode)
python stream_detection.py --pi-ip 192.168.137.211 --model best2.pt --no-display --save-video
```

**Web Interface:**
```bash
# On PC
python app.py --pi-ip 192.168.137.211

# Open browser: http://localhost:5000
```

## License

This project is provided as-is for educational and safety monitoring purposes.
