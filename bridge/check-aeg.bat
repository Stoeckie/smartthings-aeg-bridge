@echo off
cd /d "%~dp0"
"%~dp0venv\Scripts\python.exe" "%~dp0stoeckie_bridge.py" --check > "%~dp0check-aeg.txt" 2>&1
type "%~dp0check-aeg.txt"
pause
