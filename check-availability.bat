@echo off
:loop
echo %time%
curl.exe -s -o nul -w "HTTP %%{http_code}\n" http://127.0.0.1:8085/api/habits
timeout /t 1 /nobreak >nul
goto loop