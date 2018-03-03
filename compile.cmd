@echo off

if not exist bin mkdir bin

REM compile mbr.asm
nasm -f bin -o bin/mbr.bin src/boot/mbr.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile vbr.asm
nasm -f bin -o bin/vbr.bin src/boot/vbr.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile boot.asm
nasm -f bin -o bin/boot.bin src/boot/boot.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile kernel_start.asm
nasm -f elf -o bin/start.o src/kernel/start.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile kernel_keyboard.asm
nasm -f elf -o bin/keyboard.o src/kernel/keyboard.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile kernel_main.c
tcc -m32 -c src/kernel/main.c -o bin/main.o
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile kernel_screen.c
tcc -m32 -c src/kernel/screen.c -o bin/screen.o
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile kernel_pic.c
tcc -m32 -c src/kernel/pic.c -o bin/pic.o
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile kernel_idt.c
tcc -m32 -c src/kernel/idt.c -o bin/idt.o
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile kernel_paging.c
tcc -m32 -c src/kernel/paging.c -o bin/paging_c.o
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile kernel_paging.asm
nasm -f elf -o bin/paging_asm.o src/kernel/paging.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM link kernel
wlink @linker.txt
