@echo OFF
if EXIST %1 goto convert
echo Çë½«µØÍ¼ÍÏÈëbat
pause
goto finish

:convert
CD script
.\..\bin\w2l-worker.exe -e "package.cpath = [[.\\..\\bin\\?.dll]]" .\gui\mini.lua -slk "%1" > ./../log.txt
CD ..

:finish
