from flask import Flask, render_template, Response, jsonify
import cv2
import threading
import torch
import numpy as np
import time
import logging
import argparse

# PyTorch 2.6+ compatibility: disable weights_only check for legacy models
_orig_load = torch.load
torch.load = lambda f, *a, **k: _orig_load(f, *a, **{**k, 'weights_only': k.get('weights_only', False)})

from ultralytics import YOLO

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration for camera source (can be set via command line args)
CAMERA_SOURCE = 0  # Default to local webcam
PI_IP = None
PI_PORT = '8554'
PI_PATH = 'cam'

# Load your YOLO model
# Load optional person detection model (user added `best-2.pt`). If missing, person_model will be None.
model = YOLO('best2.pt')
try:
    person_model = YOLO('best-2.pt')
except Exception:
    person_model = None

# Global variable to control the detection loop
running = False
detection_thread = None

# Safety detection configuration
HELMET_CLASS_NAME = 'safety-helmet'
JACKET_CLASS_NAME = 'reflective-jacket'
CONFIDENCE_THRESHOLD = 0.5

# Colors for display
SAFE_COLOR = (0, 255, 0)  # Green
UNSAFE_COLOR = (0, 0, 255)  # Red

# Store latest detection status
detection_status = {
    'helmet_detected': False,
    'jacket_detected': False,
    'status': 'UNKNOWN',
    'timestamp': None
}

def _box_xyxy(box):
    """Return integer xyxy for a detected box object in a robust way."""
    try:
        xy = box.xyxy[0].cpu().numpy()
    except Exception:
        try:
            xy = box.xyxy[0].numpy()
        except Exception:
            # fallback: treat as list-like
            xy = list(box.xyxy[0])
    x1, y1, x2, y2 = int(xy[0]), int(xy[1]), int(xy[2]), int(xy[3])
    return x1, y1, x2, y2


def check_safety_compliance(person_results, ppe_results):
    """
    Determine per-person safety compliance by matching helmets and jackets to person boxes.

    Returns a list of dicts for each person: {'bbox': (x1,y1,x2,y2), 'helmet': bool, 'jacket': bool, 'status': 'SAFE'|'UNSAFE'}
    Also returns overall summary (person_count, safe_count, unsafe_count).
    """
    persons = []

    # Extract helmet and jacket boxes from ppe_results
    helmet_boxes = []
    jacket_boxes = []
    if ppe_results and len(ppe_results) > 0:
        pr = ppe_results[0]
        if pr.boxes is not None:
            for box in pr.boxes:
                class_id = int(box.cls[0])
                class_name = pr.names[class_id].lower()
                x1, y1, x2, y2 = _box_xyxy(box)
                if HELMET_CLASS_NAME.lower() in class_name:
                    helmet_boxes.append((x1, y1, x2, y2))
                elif JACKET_CLASS_NAME.lower() in class_name:
                    jacket_boxes.append((x1, y1, x2, y2))

    # If no person model provided, treat any detection of helmet+jacket as global
    if not person_results or len(person_results) == 0:
        return persons, {'person_count': 0, 'safe_count': 0, 'unsafe_count': 0}

    pr = person_results[0]
    if pr.boxes is None or len(pr.boxes) == 0:
        return persons, {'person_count': 0, 'safe_count': 0, 'unsafe_count': 0}

    safe_count = 0
    unsafe_count = 0

    # For each detected person, check for overlapping/contained helmet and jacket
    for pbox in pr.boxes:
        px1, py1, px2, py2 = _box_xyxy(pbox)
        # center point of helmet/jacket to check containment
        helmet_found = False
        jacket_found = False

        for (hx1, hy1, hx2, hy2) in helmet_boxes:
            cx = (hx1 + hx2) / 2.0
            cy = (hy1 + hy2) / 2.0
            if px1 <= cx <= px2 and py1 <= cy <= py2:
                helmet_found = True
                break

        for (jx1, jy1, jx2, jy2) in jacket_boxes:
            cx = (jx1 + jx2) / 2.0
            cy = (jy1 + jy2) / 2.0
            if px1 <= cx <= px2 and py1 <= cy <= py2:
                jacket_found = True
                break

        status = 'SAFE' if (helmet_found and jacket_found) else 'UNSAFE'
        if status == 'SAFE':
            safe_count += 1
        else:
            unsafe_count += 1

        persons.append({
            'bbox': (px1, py1, px2, py2),
            'helmet': helmet_found,
            'jacket': jacket_found,
            'status': status
        })

    summary = {'person_count': len(persons), 'safe_count': safe_count, 'unsafe_count': unsafe_count}
    return persons, summary

def generate_frames():
    """Generate video frames with YOLO detection and safety compliance checking."""
    global detection_status
    
    cap = None
    try:
        # Determine camera source
        if PI_IP:
            camera_source = f'rtsp://{PI_IP}:{PI_PORT}/{PI_PATH}'
            logger.info(f"Connecting to Raspberry Pi camera: {camera_source}")
        else:
            camera_source = CAMERA_SOURCE
            logger.info(f"Opening local camera: {camera_source}")
        
        # Open the camera
        cap = cv2.VideoCapture(camera_source)
        
        # Try with AVFoundation backend if default fails (for macOS with local camera)
        if not cap.isOpened() and not PI_IP:
            cap = cv2.VideoCapture(camera_source, cv2.CAP_AVFOUNDATION)
        
        if not cap.isOpened():
            logger.error(f"Could not open camera source: {camera_source}")
            return
        
        logger.info("Camera opened successfully")
        
        # Set camera resolution
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        
        frame_count = 0
        
        while running:
            ret, frame = cap.read()
            if not ret:
                logger.warning("Cannot read frame")
                break
            
            frame_count += 1
            
            # Resize if frame is too large (iPhone)
            if frame.shape[0] > 1000 or frame.shape[1] > 1000:
                frame = cv2.resize(frame, (640, 480))
            
            # Run PPE detection (helmet/jacket)
            ppe_results = model.predict(frame, conf=CONFIDENCE_THRESHOLD, verbose=False)

            # Run person detection if available
            if person_model is not None:
                person_results = person_model.predict(frame, conf=CONFIDENCE_THRESHOLD, verbose=False)
            else:
                person_results = None

            # Per-person compliance check
            persons, summary = check_safety_compliance(person_results, ppe_results)

            # Update detection_status
            detection_status['person_count'] = summary['person_count']
            detection_status['safe_count'] = summary['safe_count']
            detection_status['unsafe_count'] = summary['unsafe_count']
            detection_status['timestamp'] = time.strftime('%Y-%m-%d %H:%M:%S')
            
            # For backwards compatibility with the UI, provide aggregate helmet/jacket flags
            if summary['person_count'] == 0:
                detection_status['helmet_detected'] = False
                detection_status['jacket_detected'] = False
            else:
                detection_status['helmet_detected'] = any(p.get('helmet', False) for p in persons)
                detection_status['jacket_detected'] = any(p.get('jacket', False) for p in persons)

            # Annotate frame: start from PPE overlay so helmets/jackets are visible
            try:
                annotated_frame = ppe_results[0].plot()
            except Exception:
                annotated_frame = frame.copy()

            h, w = annotated_frame.shape[:2]

            if summary['person_count'] == 0:
                # No person detected: show a subtle message
                detection_status['status'] = 'NO_PERSON'
                cv2.rectangle(annotated_frame, (10, 10), (420, 60), (100, 100, 100), -1)
                cv2.putText(annotated_frame, "No person detected", (20, 45),
                           cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 2)
            else:
                # There are persons; draw their boxes and statuses
                # Default overall status: if any unsafe person exists, mark UNSAFE, else SAFE
                overall_status = 'SAFE'
                for p in persons:
                    px1, py1, px2, py2 = p['bbox']
                    color = SAFE_COLOR if p['status'] == 'SAFE' else UNSAFE_COLOR
                    # Draw person bbox
                    cv2.rectangle(annotated_frame, (px1, py1), (px2, py2), color, 2)
                    # Label
                    label = f"{p['status']} H:{'✓' if p['helmet'] else '✗'} J:{'✓' if p['jacket'] else '✗'}"
                    cv2.putText(annotated_frame, label, (px1 + 5, py1 + 25),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
                    if p['status'] == 'UNSAFE':
                        overall_status = 'UNSAFE'

                if overall_status == 'SAFE':
                    detection_status['status'] = 'SAFE'
                    status = "SAFE ✓"
                    status_color = SAFE_COLOR
                else:
                    detection_status['status'] = 'UNSAFE'
                    status = "UNSAFE ✗"
                    status_color = UNSAFE_COLOR

                # Overall overlay
                cv2.rectangle(annotated_frame, (10, 10), (420, 60), status_color, -1)
                cv2.putText(annotated_frame, status, (20, 45),
                           cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 2)
                details = f"Persons: {summary['person_count']} | Safe: {summary['safe_count']} | Unsafe: {summary['unsafe_count']}"
                cv2.putText(annotated_frame, details, (20, h - 20),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
            
            # Encode frame
            _, buffer = cv2.imencode('.jpg', annotated_frame)
            frame_bytes = buffer.tobytes()
            
            # Yield frame
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
    
    finally:
        # Ensure camera is properly released
        if cap is not None:
            cap.release()
            logger.info("Camera closed and released")

@app.route('/')
def index():
    """Render the main page."""
    return render_template('index.html')

@app.route('/start', methods=['POST'])
def start_detection():
    """Start the detection process."""
    global running, detection_thread
    
    # Wait if thread is still running
    if detection_thread is not None and detection_thread.is_alive():
        logger.info("⏳ Waiting for previous detection thread to finish...")
        detection_thread.join(timeout=2.0)
    
    running = True
    time.sleep(0.5)  # Allow camera time to be ready
    
    detection_thread = threading.Thread(target=generate_frames, daemon=True)
    detection_thread.start()
    logger.info("🚀 Detection STARTED")
    return {'status': 'Detection started', 'message': 'Safety detection is now live'}

@app.route('/stop', methods=['POST'])
def stop_detection():
    """Stop the detection process."""
    global running
    running = False
    time.sleep(0.5)  # Allow thread time to exit gracefully
    logger.info("⏹ Detection STOPPED")
    return {'status': 'Detection stopped'}

@app.route('/status')
def get_status():
    """Get current detection status."""
    return jsonify(detection_status)

@app.route('/video_feed')
def video_feed():
    """Stream the video feed to the browser."""
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Worker Safety Detection Flask App')
    parser.add_argument('--pi-ip', type=str, default=None,
                        help='Raspberry Pi IP address (e.g., 192.168.137.211). If not provided, uses local webcam.')
    parser.add_argument('--pi-port', type=str, default='8554',
                        help='RTSP port (default: 8554)')
    parser.add_argument('--pi-path', type=str, default='cam',
                        help='RTSP stream path (default: cam)')
    parser.add_argument('--local-camera', type=int, default=0,
                        help='Local camera index if not using Pi camera (default: 0)')
    parser.add_argument('--host', type=str, default='0.0.0.0',
                        help='Flask host (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=5000,
                        help='Flask port (default: 5000)')
    
    args = parser.parse_args()
    
    # Set global configuration
    if args.pi_ip:
        PI_IP = args.pi_ip
        PI_PORT = args.pi_port
        PI_PATH = args.pi_path
        logger.info(f"🎥 Using Raspberry Pi camera at rtsp://{PI_IP}:{PI_PORT}/{PI_PATH}")
    else:
        CAMERA_SOURCE = args.local_camera
        logger.info(f"🎥 Using local camera index: {CAMERA_SOURCE}")
    
    app.run(debug=True, host=args.host, port=args.port)