@echo off
setlocal

:: ======= SETUP ENVIRONMENT =======
echo Initializing MSVC environment...
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul

:: ====== CLEAN OBJ ======
if exist bin\obj\*.obj del /q bin\obj\*.obj

:: ====== CLEAN EXE ======
if exist bin\exe\*.exe del /q bin\exe\*.exe

:: ======= COMPILE =======
cl ^
    /std:c++20 ^
    /EHsc ^
    /nologo ^
    /c ^
    /Fo"bin\obj\\" ^
    /D "_WIN32_WINNT=0x0A00" ^
    /I src ^
    /I src\lua ^
    src\main.cpp

:: ==== CHECK ERROR ====
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed.
    exit /b %ERRORLEVEL%
)

:: ======= LINK =======
link ^
    /nologo ^
    bin\obj\*.obj ^
    /LIBPATH:src\lua lua.lib ^
    /OUT:bin\exe\mage.exe ^
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