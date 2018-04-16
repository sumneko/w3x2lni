@echo off

cd %~dp0..\script
..\bin\w3x2lni-lua.exe ..\test\convert_wtg.lua "%1"

pause
