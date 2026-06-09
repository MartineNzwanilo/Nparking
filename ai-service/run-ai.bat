@echo off
echo Starting NGEWA PARKING SYSTEM(NPS) AI Detection Service...
cd /d %~dp0
C:\Users\marti\AppData\Roaming\Python\Python314\Scripts\uvicorn.exe main:app --host 0.0.0.0 --port 8000
pause
