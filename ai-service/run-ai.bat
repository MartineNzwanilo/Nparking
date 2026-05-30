@echo off
echo Starting Locomotors AI Detection Service...
cd /d %~dp0
C:\Users\marti\AppData\Roaming\Python\Python314\Scripts\uvicorn.exe main:app --host 0.0.0.0 --port 8000
pause
