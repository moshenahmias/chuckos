@echo off

REM clean
call clean.cmd

REM compile mbr.asm
nasm -f bin -o bin/mbr.bin src/mbr.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile vbr.asm
nasm -f bin -o bin/vbr.bin src/vbr.asm
if %errorlevel% neq 0 exit /b %errorlevel%

REM compile boot.asm
nasm -f bin -o bin/boot.bin src/boot.asm
if %errorlevel% neq 0 exit /b %errorlevel%

copy disk_formatted_128m.img bin\hdd.img

REM clear 0 -> 435 (436)
dd if=/dev/zero of=bin/hdd.img bs=1 count=436 conv=notrunc

REM clear 0x10003E ->  0x1001FD (448)
dd if=/dev/zero of=bin/hdd.img seek=1048638 bs=1 count=448 conv=notrunc

REM copy MBR
dd if=bin/mbr.bin of=bin/hdd.img bs=1 count=436 conv=notrunc

REM copy MBR boot signature
dd if=bin/mbr.bin of=bin/hdd.img seek=510 bs=1 skip=510 count=2 conv=notrunc

REM copy VBR first 3 bytes
dd if=bin/vbr.bin of=bin/hdd.img seek=1048576 bs=1 count=3 conv=notrunc

REM copy VBR boot code part I + boot signature
dd if=bin/vbr.bin of=bin/hdd.img seek=1048638 bs=1 skip=62 count=450 conv=notrunc

REM copy VBR boot code part II
dd if=bin/vbr.bin of=bin/hdd.img seek=1049088 bs=1 skip=512 count=512 conv=notrunc

REM force unmount hdd if mounted
imdisk -D -m R:

REM mount hdd
imdisk -a -f bin/hdd.img -m R: -v 1
if %errorlevel% neq 0 exit /b %errorlevel%

REM copy boot.bin
copy bin\boot.bin R:\

REM unmount hdd
imdisk -d -m R:
if %errorlevel% neq 0 exit /b %errorlevel%