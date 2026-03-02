@echo off
setlocal

:: ======= SETUP ENVIRONMENT =======
echo Initializing MSVC environment...
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul

:: ====== CLEAN OBJ ======
if exist out\obj\*.obj del /q out\obj\*.obj

:: ====== CLEAN EXE ======
if exist out\exe\*.exe del /q out\exe\*.exe

:: ======= COMPILE =======
cl ^
    /std:c++20 ^
    /EHsc ^
    /nologo ^
    /c ^
    /MT ^
    /O2 ^
    /Fo"out\obj\\" ^
    /D "_WIN32_WINNT=0x0A00" ^
    /I lua ^
    lua\*.c

:: ==== CHECK ERROR ====
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed.
    exit /b %ERRORLEVEL%
)

cl ^
    /std:c++20 ^
    /EHsc ^
    /nologo ^
    /c ^
    /MT ^
    /O2 ^
    /Fo"out\obj\\" ^
    /D "_WIN32_WINNT=0x0A00" ^
    main.cpp

:: ==== CHECK ERROR ====
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed.
    exit /b %ERRORLEVEL%
)

:: ======= LINK =======
link ^
    /nologo ^
    out\obj\*.obj ^
    /OUT:out\exe\mage.exe ^
    /SUBSYSTEM:CONSOLE ^
    /MACHINE:X64

:: ==== CHECK ERROR ====
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Linking failed.
    exit /b %ERRORLEVEL%
)

:: ======= SUCCESS =======
echo [SUCCESS] Build complete.
endlocal