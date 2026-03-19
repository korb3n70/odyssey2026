@echo off
echo ================================
echo  ACME Build - Odyssey 2026 v1.0
echo ================================

cd /d C:\tools\progetti\odyssey2026

C:\tools\acme\acme.exe --cpu 6502 --format cbm ^
    --outfile odyssey2026.prg ^
    main.asm

if %ERRORLEVEL% == 0 (
    echo.
    echo  BUILD OK - Lancio VICE...
    echo ================================
    C:\tools\GTK3VICE\bin\x64sc.exe -warp -autostartprgmode 1 -autostart odyssey2026.prg
) else (
    echo.
    echo  BUILD FAILED
    echo ================================
    pause
)
