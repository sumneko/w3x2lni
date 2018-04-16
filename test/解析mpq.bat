@echo off
CHCP 65001
cd %~dp0..\script
..\bin\w2l-worker.exe ..\script\map.lua -mpq "%1"

pause
