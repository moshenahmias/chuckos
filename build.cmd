@echo off

REM clean
call clean.cmd

copy disk_formatted_128m.img bin\hdd.img

REM clear 0 -> 435 (436)
dd if=/dev/zero of=bin/hdd.img bs=1 count=436 conv=notrunc

REM clear 0x10003E ->  0x1001FD (448)
dd if=/dev/zero of=bin/hdd.img seek=1048638 bs=1 count=448 conv=notrunc

REM compile MBR
nasm -f bin -o bin/mbr.bin src/mbr.asm

REM compile VBR
nasm -f bin -o bin/vbr.bin src/vbr.asm

REM copy MBR
dd if=bin/mbr.bin of=bin/hdd.img conv=notrunc

REM copy VBR first 3 bytes
dd if=bin/vbr.bin of=bin/hdd.img seek=1048576 bs=1 count=3 conv=notrunc

REM copy VBR boot code part I + boot signature
dd if=bin/vbr.bin of=bin/hdd.img seek=1048638 bs=1 skip=62 count=450 conv=notrunc

REM copy VBR boot code part II
dd if=bin/vbr.bin of=bin/hdd.img seek=1049088 bs=1 skip=512 count=512 conv=notrunc