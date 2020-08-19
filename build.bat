@echo off
rem Make sure to link your GNU Assembler and MSVC Linker to PATH
rem Replace this with your 'vcvars64' if it's different
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

set output_file_name=Snake

start /b /wait "" "as" first.s -o build/first.obj
start /b /wait "" "cl" build/first.obj /link /nologo /machine:x64 /subsystem:windows /debug:none /entry:entry /out:build/%output_file_name%.exe kernel32.lib user32.lib Gdi32.lib
