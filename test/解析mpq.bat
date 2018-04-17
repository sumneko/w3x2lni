@echo off
CHCP 65001
cd %~dp0..\script
..\bin\w3x2lni-lua.exe ..\script\map.lua mpq "%1"

pause
