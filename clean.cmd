@echo off

REM force unmount hdd if mounted
imdisk -D -m R:

REM clean
del bin\* /F /Q