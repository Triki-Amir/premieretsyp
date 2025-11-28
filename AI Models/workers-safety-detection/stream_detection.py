"""
Real-time safety equipment detection from Raspberry Pi camera stream.
Connects to RTSP stream from Pi and runs YOLO detection on PC.
"""

from ultralytics import YOLO
import cv2
import argparse
import sys
from datetime import datetime

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Stream safety detection from Raspberry Pi camera')
    parser.add_argument('--pi-ip', type=str, required=True,
                        help='Raspberry Pi IP address (e.g., 192.168.1.100)')
    parser.add_argument('--port', type=str, default='8554',
                        help='Stream port (default: 8554)')
    parser.add_argument('--path', type=str, default='cam',
                        help='RTSP stream path (default: cam)')
    parser.add_argument('--protocol', type=str, default='rtsp', choices=['rtsp', 'http', 'tcp', 'udp'],
                        help='Streaming protocol: rtsp, http, tcp, or udp (default: rtsp)')
    parser.add_argument('--model', type=str, default='best.pt',
                        help='Path to YOLO model weights (default: best.pt)')
    parser.add_argument('--device', type=str, default='cpu',
                        help='Inference device: cpu or cuda (default: cpu)')
    parser.add_argument('--conf', type=float, default=0.5,
                        help='Confidence threshold (default: 0.5)')
    parser.add_argument('--save-video', action='store_true',
                        help='Save annotated video output')
    parser.add_argument('--no-display', action='store_true',
                        help='Run without display window')
    return parser.parse_args()

def main():
    """Main function to run stream detection."""
    args = parse_args()
    
    # Construct stream URL based on protocol
    if args.protocol == 'rtsp':
        stream_url = f'rtsp://{args.pi_ip}:{args.port}/{args.path}'
    elif args.protocol == 'http':
        stream_url = f'http://{args.pi_ip}:{args.port}'
    elif args.protocol == 'tcp':
        stream_url = f'tcp://{args.pi_ip}:{args.port}'
    elif args.protocol == 'udp':
        stream_url = f'udp://0.0.0.0:{args.port}'
        print(f"[INFO] Listening for UDP stream on port {args.port}")
        print(f"[INFO] Make sure Pi is sending to your PC's IP on port {args.port}")
    
    print(f"[INFO] Connecting to: {stream_url}")
    
    video_writer = None
    cap = None
    
    try:
        # Load YOLO model
        print(f"[INFO] Loading model: {args.model}")
        model = YOLO(args.model)
        model.to(args.device)
        
        # Setup video writer if saving
        if args.save_video:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_path = f'output_{timestamp}.mp4'
            fourcc = cv2.VideoWriter_fourcc(*'mp4v')
            # Will initialize after first frame to get dimensions
            print(f"[INFO] Will save output to: {output_path}")
        
        # Connect to stream
        print("[INFO] Connecting to camera stream...")
        cap = cv2.VideoCapture(stream_url)
        
        if not cap.isOpened():
            print("[ERROR] Failed to connect to stream. Check:")
            print("  1. Pi IP address is correct")
            print(f"  2. {args.protocol.upper()} server is running on Pi")
            print(f"  3. Port {args.port} is open")
            print("  4. Both devices are on same network")
            return
        
        print("[INFO] Stream connected! Starting detection...")
        print("[INFO] Press 'q' to quit, 's' to save screenshot")
        
        frame_count = 0
        
        # Run inference on stream
        for result in model(stream_url, stream=True, conf=args.conf, device=args.device):
            frame_count += 1
            
            # Get annotated frame with bounding boxes
            annotated_frame = result.plot()
            
            # Initialize video writer with actual frame dimensions
            if args.save_video and video_writer is None:
                height, width = annotated_frame.shape[:2]
                video_writer = cv2.VideoWriter(output_path, fourcc, 25.0, (width, height))
            
            # Save frame to video
            if video_writer is not None:
                video_writer.write(annotated_frame)
            
            # Display frame
            if not args.no_display:
                # Add frame counter and FPS info
                cv2.putText(annotated_frame, f'Frame: {frame_count}', 
                           (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                
                cv2.imshow('Pi Safety Detection', annotated_frame)
                
                key = cv2.waitKey(1) & 0xFF
                
                # Quit on 'q'
                if key == ord('q'):
                    print("[INFO] Quit signal received")
                    break
                
                # Save screenshot on 's'
                elif key == ord('s'):
                    screenshot_path = f'screenshot_{datetime.now().strftime("%Y%m%d_%H%M%S")}.jpg'
                    cv2.imwrite(screenshot_path, annotated_frame)
                    print(f"[INFO] Screenshot saved: {screenshot_path}")
            
            # Print detections every 30 frames
            if frame_count % 30 == 0:
                detections = len(result.boxes)
                if detections > 0:
                    print(f"[INFO] Frame {frame_count}: {detections} objects detected")
    
    except KeyboardInterrupt:
        print("\n[INFO] Interrupted by user")
    
    except Exception as e:
        print(f"[ERROR] An error occurred: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Cleanup
        print("[INFO] Cleaning up...")
        if cap is not None and cap.isOpened():
            cap.release()
        if video_writer is not None:
            video_writer.release()
        cv2.destroyAllWindows()
        print("[INFO] Done!")

if __name__ == '__main__':
    main()
