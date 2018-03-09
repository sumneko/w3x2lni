@echo off

cd %~dp0..
..\bin\w2l-worker.exe test\convert_wtg.lua "%1"

pause
