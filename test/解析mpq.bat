@echo off

cd %~dp0..\script
..\bin\w2l-worker.exe ..\test\custom_mpq.lua "%1" "custom"

pause
