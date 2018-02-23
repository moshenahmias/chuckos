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

REM compile kernel_jmp.asm
nasm -f elf -o bin/kernel_jmp.o src/kernel_jmp.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile kernel_main.c
tcc -m32 -c src/kernel_main.c -o bin/kernel_main.o
if %errorlevel% neq 0 exit /b %errorlevel%

REM link kernel_jmp.o and kernel_main.o
tcc -nostdlib bin/kernel_jmp.o bin/kernel_main.o -o bin/kernel.tmp 
if %errorlevel% neq 0 exit /b %errorlevel%

REM extract text from kernel.pe
objcopy -O binary -j .text bin/kernel.tmp bin/kernel.bin
if %errorlevel% neq 0 exit /b %errorlevel%