@echo off
REM Gangster Town Adventures - Game Launcher
REM This batch file launches the game directly

set GODOT_PATH=C:\Users\phani\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe
set PROJECT_PATH=d:\GTA_LITE\GangsterTownAdventures

echo ==========================================
echo   GANGSTER TOWN ADVENTURES
echo ==========================================
echo.
echo Starting the game...
echo.

"%GODOT_PATH%" --path "%PROJECT_PATH%"
