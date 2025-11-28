"""
Construction Worker Safety Detection System

This script uses a custom YOLO model to detect construction workers and verify
if they are wearing proper safety equipment (helmets and safety jackets).

Features:
- Real-time detection from webcam or RTSP stream
- Safety compliance checking (helmet + jacket)
- Webhook notifications for safe workers
- Webhook alerts for safety violations
- Visual feedback with color-coded bounding boxes

Author: YOLO Safety Detection System
"""

import cv2
import requests
import torch
import time

# PyTorch 2.6+ compatibility: disable weights_only check for legacy models
_orig_load = torch.load
torch.load = lambda f, *a, **k: _orig_load(f, *a, **{**k, 'weights_only': k.get('weights_only', False)})

from ultralytics import YOLO


# ========== CONFIGURATION ==========
# Model path - custom YOLO model trained to detect helmets and safety jackets
MODEL_PATH = 'best2.pt'

# Video source configuration
# Option 1: Use webcam (0 for default camera, 1 for second camera, etc.)
VIDEO_SOURCE = 0
# Option 2: Use RTSP stream (uncomment and modify as needed)
# VIDEO_SOURCE = 'rtsp://username:password@ip_address:port/stream'

# Webhook endpoints for notifications and alerts
# Set to None to disable webhook notifications
NOTIFICATION_WEBHOOK_URL = None  # 'https://webhook.site/notification-placeholder'
ALERT_WEBHOOK_URL = None  # 'https://webhook.site/alert-placeholder'

# Detection confidence threshold
CONFIDENCE_THRESHOLD = 0.5

# Display configuration
WINDOW_NAME = 'Construction Safety Detection - Press Q to Quit'
SAFE_COLOR = (0, 255, 0)  # Green for safe workers
UNSAFE_COLOR = (0, 0, 255)  # Red for unsafe workers
TEXT_COLOR = (255, 255, 255)  # White text
BOX_THICKNESS = 2
FONT = cv2.FONT_HERSHEY_SIMPLEX
FONT_SCALE = 0.7
FONT_THICKNESS = 2

# Expected class names in the YOLO model
# Modify these to match your model's class names
HELMET_CLASS_NAME = 'safety-helmet'
JACKET_CLASS_NAME = 'reflective-jacket'
# ====================================


def load_model():
    """
    Load the custom YOLO model for safety equipment detection.
    
    This function loads the pre-trained YOLO model from the specified path.
    The model should be trained to detect helmets and safety jackets.
    
    Returns:
        YOLO: Loaded YOLO model object ready for inference
        
    Raises:
        Exception: If the model file cannot be found or loaded
    """
    try:
        print(f"Loading YOLO model from: {MODEL_PATH}")
        model = YOLO(MODEL_PATH)
        print("✓ Model loaded successfully!")
        return model
    except Exception as e:
        print(f"✗ Error loading model: {e}")
        raise


def process_frame(model, frame):
    """
    Process a single video frame through the YOLO model.
    
    This function runs YOLO object detection on the input frame to identify
    helmets, safety jackets, and workers.
    
    Args:
        model (YOLO): The loaded YOLO model
        frame (numpy.ndarray): The video frame to process (BGR format)
        
    Returns:
        list: YOLO detection results containing bounding boxes, classes, and confidences
    """
    # Run YOLO prediction on the frame
    # conf parameter sets the confidence threshold for detections
    # verbose=False suppresses output logs for cleaner display
    results = model.predict(frame, conf=CONFIDENCE_THRESHOLD, verbose=False)
    return results


def check_safety_compliance(results):
    """
    Analyze YOLO detections to determine safety equipment compliance.
    
    This function examines all detections in the frame and checks if both
    a helmet and a safety jacket are present, indicating the worker is safe.
    
    Args:
        results (list): YOLO detection results from process_frame()
        
    Returns:
        tuple: (helmet_detected, jacket_detected)
            - helmet_detected (bool): True if helmet is detected
            - jacket_detected (bool): True if safety jacket is detected
    """
    helmet_detected = False
    jacket_detected = False
    
    # Check if we have any results
    if not results or len(results) == 0:
        return helmet_detected, jacket_detected
    
    # Get the first result (single frame prediction)
    result = results[0]
    
    # Check if there are any detections
    if result.boxes is None or len(result.boxes) == 0:
        return helmet_detected, jacket_detected
    
    # Iterate through all detected objects
    for box in result.boxes:
        # Get the class ID and convert to class name
        class_id = int(box.cls[0])
        class_name = result.names[class_id].lower()
        
        # Check if this detection is a helmet or safety jacket
        if HELMET_CLASS_NAME.lower() in class_name:
            helmet_detected = True
        elif JACKET_CLASS_NAME.lower() in class_name:
            jacket_detected = True
    
    return helmet_detected, jacket_detected


def send_notification(message):
    """
    Send a notification webhook for safe workers.
    
    This function sends a POST request to the notification webhook endpoint
    when a worker is detected with proper safety equipment (helmet + jacket).
    
    Args:
        message (str): The notification message to send
        
    Returns:
        bool: True if notification was sent successfully, False otherwise
    """
    # Skip if webhook is disabled
    if NOTIFICATION_WEBHOOK_URL is None:
        return True
    
    try:
        # Prepare the payload with notification details
        payload = {
            'type': 'safety_compliance',
            'status': 'SAFE',
            'message': message,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        # Send POST request to the webhook endpoint
        response = requests.post(
            NOTIFICATION_WEBHOOK_URL,
            json=payload,
            timeout=5
        )
        
        # Check if the request was successful
        if response.status_code == 200:
            print(f"✓ Notification sent: {message}")
            return True
        else:
            print(f"⚠ Notification failed with status {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        # Handle network errors gracefully
        print(f"⚠ Notification error: {e}")
        return False


def send_alert(message):
    """
    Send an alert webhook for safety violations.
    
    This function sends a POST request to the alert webhook endpoint when
    a worker is detected without proper safety equipment (missing helmet or jacket).
    
    Args:
        message (str): The alert message to send
        
    Returns:
        bool: True if alert was sent successfully, False otherwise
    """
    # Skip if webhook is disabled
    if ALERT_WEBHOOK_URL is None:
        return True
    
    try:
        # Prepare the payload with alert details
        payload = {
            'type': 'safety_violation',
            'status': 'UNSAFE',
            'message': message,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        # Send POST request to the webhook endpoint
        response = requests.post(
            ALERT_WEBHOOK_URL,
            json=payload,
            timeout=5
        )
        
        # Check if the request was successful
        if response.status_code == 200:
            print(f"⚠ Alert sent: {message}")
            return True
        else:
            print(f"✗ Alert failed with status {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        # Handle network errors gracefully
        print(f"✗ Alert error: {e}")
        return False


def draw_detections_on_frame(frame, results, helmet_detected, jacket_detected):
    """
    Draw bounding boxes and safety status labels on the video frame.
    
    This function annotates the frame with:
    - Bounding boxes around detected objects (helmet, jacket)
    - Safety status label ("SAFE" in green or "UNSAFE" in red)
    - Object class labels with confidence scores
    
    Args:
        frame (numpy.ndarray): The original video frame
        results (list): YOLO detection results
        helmet_detected (bool): Whether a helmet was detected
        jacket_detected (bool): Whether a safety jacket was detected
        
    Returns:
        numpy.ndarray: Annotated frame with bounding boxes and labels
    """
    # Create a copy of the frame to draw on
    annotated_frame = frame.copy()
    
    # Determine safety status and corresponding color
    is_safe = helmet_detected and jacket_detected
    status_text = "SAFE" if is_safe else "UNSAFE"
    status_color = SAFE_COLOR if is_safe else UNSAFE_COLOR
    
    # Draw detections if any exist
    if results and len(results) > 0:
        result = results[0]
        
        if result.boxes is not None and len(result.boxes) > 0:
            # Draw each detected object
            for box in result.boxes:
                # Get bounding box coordinates
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                
                # Get class name and confidence
                class_id = int(box.cls[0])
                class_name = result.names[class_id]
                confidence = float(box.conf[0])
                
                # Draw bounding box
                cv2.rectangle(
                    annotated_frame,
                    (x1, y1),
                    (x2, y2),
                    status_color,
                    BOX_THICKNESS
                )
                
                # Prepare label text with class name and confidence
                label = f"{class_name}: {confidence:.2f}"
                
                # Calculate label background size
                (label_width, label_height), baseline = cv2.getTextSize(
                    label,
                    FONT,
                    FONT_SCALE * 0.6,
                    FONT_THICKNESS - 1
                )
                
                # Draw label background
                cv2.rectangle(
                    annotated_frame,
                    (x1, y1 - label_height - 10),
                    (x1 + label_width, y1),
                    status_color,
                    -1
                )
                
                # Draw label text
                cv2.putText(
                    annotated_frame,
                    label,
                    (x1, y1 - 5),
                    FONT,
                    FONT_SCALE * 0.6,
                    TEXT_COLOR,
                    FONT_THICKNESS - 1
                )
    
    # Draw overall safety status at the top of the frame
    status_label = f"Status: {status_text}"
    if not is_safe:
        # Add details about what's missing
        missing_items = []
        if not helmet_detected:
            missing_items.append("helmet")
        if not jacket_detected:
            missing_items.append("safety jacket")
        status_label += f" - Missing: {', '.join(missing_items)}"
    
    # Calculate status label background size
    (status_width, status_height), baseline = cv2.getTextSize(
        status_label,
        FONT,
        FONT_SCALE,
        FONT_THICKNESS
    )
    
    # Draw status label background at top of frame
    cv2.rectangle(
        annotated_frame,
        (10, 10),
        (20 + status_width, 20 + status_height),
        status_color,
        -1
    )
    
    # Draw status label text
    cv2.putText(
        annotated_frame,
        status_label,
        (15, 15 + status_height),
        FONT,
        FONT_SCALE,
        TEXT_COLOR,
        FONT_THICKNESS
    )
    
    return annotated_frame


def main():
    """
    Main function to run the construction worker safety detection system.
    
    This function orchestrates the entire workflow:
    1. Load the YOLO model
    2. Open the video stream (webcam or RTSP)
    3. Process each frame to detect safety equipment
    4. Check safety compliance (helmet + jacket)
    5. Send notifications or alerts via webhooks
    6. Display annotated video with safety status
    7. Continue until user presses 'q'
    """
    print("=" * 60)
    print("Construction Worker Safety Detection System")
    print("=" * 60)
    
    # Step 1: Load the YOLO model
    print("\n[Step 1/4] Loading YOLO model...")
    try:
        model = load_model()
    except Exception:
        print("Failed to load model. Exiting.")
        return
    
    # Step 2: Open video source (webcam or RTSP stream)
    print(f"\n[Step 2/4] Opening video source: {VIDEO_SOURCE}")
    cap = cv2.VideoCapture(VIDEO_SOURCE)
    
    # Try with different backend if default fails (for macOS Continuity Camera)
    if not cap.isOpened():
        print("  Trying with AVFoundation backend...")
        cap = cv2.VideoCapture(VIDEO_SOURCE, cv2.CAP_AVFOUNDATION)
    
    if not cap.isOpened():
        print("✗ Error: Could not open video source")
        print("  - If using webcam, make sure it's connected and not in use")
        print("  - If using RTSP, verify the URL and credentials")
        print("  - macOS: Grant camera permissions in System Preferences > Security & Privacy > Camera")
        return
    
    print("✓ Video source opened successfully")
    
    # Get video properties for information
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    print(f"  Video properties: {width}x{height} @ {fps} FPS")
    
    # Step 3: Start detection loop
    print("\n[Step 3/4] Starting detection loop...")
    print("Press 'q' in the video window to quit\n")
    
    # Track when we last sent a notification/alert to avoid spam
    last_notification_time = 0
    last_alert_time = 0
    notification_cooldown = 10  # Seconds between notifications/alerts
    
    frame_count = 0
    
    try:
        while True:
            # Read a frame from the video source
            ret, frame = cap.read()
            
            if not ret:
                print("✗ Error: Cannot read frame (stream may have ended)")
                break
            
            frame_count += 1
            
            # Step 3a: Process the frame through YOLO model
            results = process_frame(model, frame)
            
            # Step 3b: Check safety compliance (helmet + jacket detection)
            helmet_detected, jacket_detected = check_safety_compliance(results)
            
            # Step 3c: Determine safety status
            is_safe = helmet_detected and jacket_detected
            
            # Step 3d: Send notifications or alerts (with cooldown to avoid spam)
            current_time = time.time()
            
            if is_safe:
                # Worker is safe - send notification if cooldown has passed
                if current_time - last_notification_time > notification_cooldown:
                    message = "Safe Worker: Helmet and safety jacket detected"
                    send_notification(message)
                    last_notification_time = current_time
            else:
                # Worker is unsafe - send alert if cooldown has passed
                if current_time - last_alert_time > notification_cooldown:
                    missing = []
                    if not helmet_detected:
                        missing.append("helmet")
                    if not jacket_detected:
                        missing.append("Reflective jacket")
                    message = f"ALERT: Missing safety gear - {', '.join(missing)}"
                    send_alert(message)
                    last_alert_time = current_time
            
            # Step 3e: Draw bounding boxes and labels on the frame
            annotated_frame = draw_detections_on_frame(
                frame,
                results,
                helmet_detected,
                jacket_detected
            )
            
            # Step 3f: Display the annotated frame
            cv2.imshow(WINDOW_NAME, annotated_frame)
            
            # Step 3g: Check if user pressed 'q' to quit
            if cv2.waitKey(1) & 0xFF == ord('q'):
                print("\n[Step 4/4] User pressed 'q' - stopping detection")
                break
                
    except KeyboardInterrupt:
        print("\n[Step 4/4] Interrupted by user (Ctrl+C)")
    except Exception as e:
        print(f"\n✗ Error during detection: {e}")
    finally:
        # Cleanup: Release video capture and close windows
        print("\nCleaning up...")
        cap.release()
        cv2.destroyAllWindows()
        print(f"✓ Processed {frame_count} frames")
        print("✓ Detection system stopped")
        print("=" * 60)


if __name__ == "__main__":
    # Run the main function when script is executed directly
    main()
