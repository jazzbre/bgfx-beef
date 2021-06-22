@echo off
cd submodules\bgfx
..\bx\tools\bin\windows\genie --with-windows=10.0 --with-tools vs2019
cd ..\..
xcopy /Y submodules\bgfx\bindings\bf\bgfx.bf src\

echo Check Visual Studio version
IF EXIST "c:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE" (
echo Using Visual Studio 2019 Professional Path
set "VISUALSTUDIO19PATH=c:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE"
) else (
echo Using Visual Studio 2019 Community Path
set "VISUALSTUDIO19PATH=c:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE"
)

IF EXIST "%VISUALSTUDIO19PATH%" (
echo Building BGFX Debug in Visual Studio 2019
"%VISUALSTUDIO19PATH%\devenv" "submodules\bgfx\.build\projects\vs2019\bgfx.sln" /Build "Debug|x64"
echo ErrorLevel:%ERRORLEVEL%
IF %ERRORLEVEL% EQU 0 (
   echo Build successful!
) else (
   echo Build failed!
)
echo Building BGFX Release in Visual Studio 2019
"%VISUALSTUDIO19PATH%\devenv" "submodules\bgfx\.build\projects\vs2019\bgfx.sln" /Build "Release|x64"
echo ErrorLevel:%ERRORLEVEL%
IF %ERRORLEVEL% EQU 0 (
   echo Build successful!
) else (
   echo Build failed!
)
) else (
echo Visual Studio 2019 not found! Open 'submodules\bgfx\.build\projects\vs2019\bgfx.sln' yourself and build it with your own version (NOTE you'll need to change vs2019 above to your installed version)
)

pause