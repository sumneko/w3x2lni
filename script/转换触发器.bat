@echo off

%~d0
cd %~dp0
.\..\bin\w2l-worker.exe convert_wtg.lua "%1"

pause
