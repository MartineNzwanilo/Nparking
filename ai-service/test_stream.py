import cv2
import sys

url = "http://192.168.2.39:8080/video"
print(f"Opening {url} ...")
cap = cv2.VideoCapture(url)
if not cap.isOpened():
    print("Failed to open.")
    sys.exit(1)

print("Opened! Reading frame...")
ret, frame = cap.read()
print(f"ret={ret}, frame={frame.shape if frame is not None else None}")
cap.release()
