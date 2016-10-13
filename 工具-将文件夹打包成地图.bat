@echo off
"%~dp0build\lua.exe" "%~dp0src\make.lua" "%~dp0\" "pack" %1
pause
