@echo off

%~d0
cd %~dp0
.\..\bin\w2l-worker.exe -e "BAT=true" main.lua -convert_wtg "%1" C:\Users\actboy168\GitHub\YDWE\Development\Component\

pause
