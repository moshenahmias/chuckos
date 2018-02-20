@echo off

REM compile mbr.asm
nasm -f bin -o bin/mbr.bin src/mbr.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile vbr.asm
nasm -f bin -o bin/vbr.bin src/vbr.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile boot.asm
nasm -f bin -o bin/boot.bin src/boot.asm
if %errorlevel% neq 0 exit /b %errorlevel%