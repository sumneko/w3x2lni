@echo off
"%~dp0build\lua.exe" "%~dp0src\make.lua" "unpack" "%~dp0\" %1
pause
