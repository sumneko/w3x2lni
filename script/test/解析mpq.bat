@echo off

cd %~dp0..
..\bin\w2l-worker.exe test\custom_mpq.lua "%1" "custom"

pause
