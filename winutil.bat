@echo off
REM Launch PowerShell and execute the Invoke‑RestMethod & Invoke‑Expression command
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://christitus.com/win' | iex"
