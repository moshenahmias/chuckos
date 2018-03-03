@echo off

REM force unmount hdd if mounted
imdisk -D -m R:

REM clean
if exist bin del bin\* /F /Q