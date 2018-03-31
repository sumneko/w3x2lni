@echo off

cd %~dp0..\script
..\bin\w2l-worker.exe ..\test\convert_wtg.lua "%1"

pause
