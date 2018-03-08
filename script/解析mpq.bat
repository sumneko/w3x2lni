@echo off

%~d0
cd %~dp0
%~dp0..\bin\w2l-worker.exe %~dp0main.lua -mpq "%1" "custom"

pause
