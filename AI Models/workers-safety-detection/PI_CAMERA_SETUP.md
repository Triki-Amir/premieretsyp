# Raspberry Pi Camera Streaming Setup

This guide explains how to set up your Raspberry Pi 4 as a camera server and run YOLO detection on your PC.

## Part 1: Raspberry Pi Setup

### 1. Install Required Packages
```bash
sudo apt update
sudo apt install vlc
```

### 2. Enable Camera
```bash
sudo raspi-config
# Navigate to: Interface Options > Camera > Enable
# Reboot if prompted
```

### 3. Test Camera
```bash
rpicam-hello
# You should see a preview window
```

### 4. Start RTSP Stream
Run this command to start streaming:
```bash
rpicam-vid -t 0 -o - --inline -w 640 -h 480 -fps 25 | cvlc -vvv stream:///dev/stdin --sout '#rtp{sdp=rtsp://:8554/stream}' :demux=h264
```

**Parameters:**
- `-w 640 -h 480`: Resolution (adjust as needed)
- `-fps 25`: Frame rate
- Port `8554`: Default RTSP port

### 5. Find Pi IP Address
```bash
hostname -I
# Note the first IP address (e.g., 192.168.1.100)
```

### 6. Make Stream Auto-Start (Optional)
Create a systemd service:
```bash
sudo nano /etc/systemd/system/camera-stream.service
```

Add:
```ini
[Unit]
Description=Raspberry Pi Camera RTSP Stream
After=network.target

[Service]
ExecStart=/bin/bash -c 'rpicam-vid -t 0 -o - --inline -w 640 -h 480 -fps 25 | cvlc -vvv stream:///dev/stdin --sout "#rtp{sdp=rtsp://:8554/stream}" :demux=h264'
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable camera-stream.service
sudo systemctl start camera-stream.service
sudo systemctl status camera-stream.service
```

## Part 2: PC Setup and Usage

### 1. Test Stream with VLC
- Open VLC Media Player
- Media > Open Network Stream
- Enter: `rtsp://<PI_IP>:8554/stream`
- Click Play

### 2. Run YOLO Detection
```bash
python stream_detection.py --pi-ip 192.168.1.100 --model best.pt --device cuda
```

**Arguments:**
- `--pi-ip`: Your Raspberry Pi's IP address (required)
- `--model`: Path to your YOLO model file
- `--device`: Use 'cuda' for GPU, 'cpu' for CPU
- `--conf`: Confidence threshold (default: 0.5)
- `--save-video`: Save annotated output video
- `--no-display`: Run without display window
- `--port`: RTSP port (default: 8554)

**Examples:**
```bash
# Basic usage
python stream_detection.py --pi-ip 192.168.1.100

# With GPU and video saving
python stream_detection.py --pi-ip 192.168.1.100 --device cuda --save-video

# Headless mode (no display)
python stream_detection.py --pi-ip 192.168.1.100 --no-display --save-video

# Custom confidence threshold
python stream_detection.py --pi-ip 192.168.1.100 --conf 0.7
```

## Troubleshooting

### Stream Not Connecting
1. **Check Pi IP**: Run `hostname -I` on Pi
2. **Check stream is running**: On Pi, run `ps aux | grep rpicam`
3. **Test with VLC first**: Ensure stream works before YOLO
4. **Firewall**: Open port 8554 on both devices
5. **Network**: Ensure both devices are on same network

### Low FPS / Lag
- Lower resolution: Change `-w 640 -h 480` to `-w 320 -h 240`
- Lower frame rate: Change `-fps 25` to `-fps 15`
- Use Ethernet instead of Wi-Fi
- Reduce YOLO model size (use YOLOv8n instead of YOLOv8m/l)

### Poor Detection Quality
- Increase resolution on Pi stream
- Adjust `--conf` threshold
- Ensure good lighting at Pi location
- Retrain model if needed for your specific setup

### Pi Stream Crashes
- Check Pi power supply (need 5V/3A minimum)
- Monitor Pi temperature: `vcgencmd measure_temp`
- Add cooling if temperature exceeds 70°C

## Performance Tips

1. **For best latency**: Use Ethernet connection
2. **For best FPS**: Use GPU on PC (`--device cuda`)
3. **For stability**: Run Pi stream as systemd service
4. **For remote access**: Set up port forwarding on router (port 8554)

## Security Note

This setup streams unencrypted video over local network. For production:
- Use VPN if accessing remotely
- Consider adding authentication to RTSP stream
- Use RTSPS (RTSP over TLS) for encrypted streaming

## Quick Reference

### Start stream on Pi:
```bash
rpicam-vid -t 0 -o - --inline -w 640 -h 480 -fps 25 | cvlc -vvv stream:///dev/stdin --sout '#rtp{sdp=rtsp://:8554/stream}' :demux=h264
```

### Run detection on PC:
```bash
python stream_detection.py --pi-ip <PI_IP> --model best.pt --device cuda
```

### Stop stream on Pi:
```bash
# If running in terminal: Ctrl+C
# If running as service:
sudo systemctl stop camera-stream.service
```
