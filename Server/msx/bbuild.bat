@echo off
setlocal enabledelayedexpansion
if .%1 neq .all goto :nodel
del opcs_core.rel
del transport_tcp-unapi.rel
:nodel
set COMMON_ARGS=-mz80 --disable-warning 196 --disable-warning 85 --max-allocs-per-node 100000 --allow-unsafe-read --opt-code-speed

if not exist crt0_msxbasic.rel goto :docrt0
for %%i in ("crt0_msxbasic.s") do set ATTRIBS=%%~ai
set ARCHIVE=!ATTRIBS:~2,1! 
if %ARCHIVE% neq a goto :crt0ok
:docrt0
echo --- Building crt0 for MSX-BASIC...
sdasz80 -o crt0_msxbasic.rel crt0_msxbasic.s
if errorlevel 1 goto :end
attrib -a crt0_msxbasic.s
:crt0ok


if not exist opcs_core.rel goto :docore
for %%i in ("opcs_core.c") do set ATTRIBS=%%~ai
set ARCHIVE=!ATTRIBS:~2,1! 
if %ARCHIVE% neq a goto :coreok
:docore
echo --- Building server core...
sdcc -c %COMMON_ARGS% opcs_core.c
if errorlevel 1 goto :end
attrib -a opcs_core.c
:coreok

if not exist transport_tcp-unapi.rel goto :dotransport
for %%i in ("transport_tcp-unapi.c") do set ATTRIBS=%%~ai
set ARCHIVE=!ATTRIBS:~2,1! 
if %ARCHIVE% neq a goto :transportok
:dotransport
echo --- Building transport module...
sdcc -c %COMMON_ARGS%  transport_tcp-unapi.c
if errorlevel 1 goto :end
attrib -a transport_tcp-unapi.c
:transportok

echo --- Building server app...
sdcc -o opcs.ihx --code-loc 0xA020 --data-loc 0 %COMMON_ARGS% --no-std-crt0 crt0_msxbasic.rel putchar_msxbasic.rel printf.rel asm.lib opcs_core.rel transport_tcp-unapi.rel opcs_msx-basic.c
if errorlevel 1 goto :end
hex2bin -e bin opcs.ihx

echo --- Mounting disk image file...
call mount.bat
if errorlevel 1 goto :end

echo --- Copying file...
copy opcs.bin Y:

echo --- Unmounting disk image file...
ping 1.1.1.1 -n 1 -w 1500 >NUL
call unmount.bat

:end
endlocal
