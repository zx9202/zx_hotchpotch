@echo off

cmdkey   /list:git:https://github.com

set /p INPUT=ÒªÉ¾³ý¸ÃÆ¾Ö¤Âð£¿[y/N]: 

if /i "%INPUT%"=="y" (
cmdkey /delete:git:https://github.com
echo.
) else (
echo.
echo Î´É¾³ý
echo\
)

pause
