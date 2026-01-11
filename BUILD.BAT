@ECHO OFF
REM Build script for DOS Game Launcher
REM Requires Turbo Pascal 5.5 minimum (TP 7.0 preferred) or compatible

ECHO Building DOS Game Launcher...
ECHO.

ECHO Compiling shared unit...
ECHO   - GAMETYPE.PAS...
TPC GAMETYPE.PAS
IF ERRORLEVEL 1 GOTO ERROR

ECHO Compiling importer...
ECHO   - IMPORT.PAS...
TPC IMPORT.PAS
IF ERRORLEVEL 1 GOTO ERROR

ECHO.
ECHO Compiling 80s/XT version...
ECHO   - MENU.PAS...
TPC MENU.PAS
IF ERRORLEVEL 1 GOTO ERROR

ECHO   - EDITMENU.PAS...
TPC EDITMENU.PAS
IF ERRORLEVEL 1 GOTO ERROR

ECHO.
ECHO Compiling 486+ version...
ECHO   - MENU486.PAS...
TPC MENU486.PAS
IF ERRORLEVEL 1 GOTO ERROR

ECHO   - EDIT486.PAS...
TPC EDIT486.PAS
IF ERRORLEVEL 1 GOTO ERROR

ECHO.
ECHO Build complete!
ECHO.
ECHO 80s/XT Systems:
ECHO   Run EDITMENU.EXE to add games
ECHO   Run MENU.EXE to launch games
ECHO.
ECHO 486+ Systems:
ECHO   Run EDIT486.EXE to add games (extended sound + slowdown)
ECHO   Run MENU486.EXE to launch games (FM/MIDI filtering)
GOTO END

:NOCOMPILER
ECHO Error: TPC.EXE not found!
ECHO Please ensure Turbo Pascal is installed and TPC.EXE is in your PATH
GOTO END

:ERROR
ECHO.
ECHO Build failed with errors!

:END
