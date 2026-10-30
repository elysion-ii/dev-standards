@echo off
rem Exports every database listed in export-schema.json into <this folder>\<database>\.
rem Prompts for the user and password the file leaves empty.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Export-Schema.ps1" %*
if errorlevel 1 (
    echo.
    echo Export failed.
    pause
    exit /b 1
)
pause
