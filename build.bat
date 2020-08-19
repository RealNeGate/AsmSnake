@echo off
rem Setup your GNU Assembler to your PATH
rem Setup your MSVC Linker to your PATH

set output_file_name=Snake

rem Replace this with your Window Kits
set winsdk="C:/Program Files (x86)/Windows Kits/10/lib/10.0.18362.0/um/x64"

start /b /wait "" "as" first.s -o build/first.obj
start /b /wait "" "cl" build/first.obj /link /nologo /libpath:%winsdk% /machine:x64 /subsystem:windows /debug:none /entry:entry /out:%output_file_name%.exe kernel32.lib user32.lib Gdi32.lib
