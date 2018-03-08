@echo off

%~d0
cd %~dp0
.\..\bin\w2l-worker.exe -e "BAT=true" convert_wtg.lua "%1"

pause
