@echo off

pushd submodules\bgfx\scripts
..\..\bx\tools\bin\windows\genie idl
popd

pushd submodules\bgfx
..\bx\tools\bin\windows\genie --with-windows=10.0 --with-tools vs2022
popd

xcopy /Y submodules\bgfx\bindings\bf\bgfx.bf src\

echo Check Visual Studio version
IF EXIST "c:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" (
echo -- Using Visual Studio 2022 Professional Path
set "MSBUILD=c:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
) else (
   IF EXIST "c:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" (
      echo -- Using Visual Studio 2022 Community Path
      set "MSBUILD=c:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
   ) else (   
      set "MSBUILD=c:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
   )
)

IF EXIST "%MSBUILD%" (
echo Building BGFX Debug in Visual Studio 2022
call "%MSBUILD%" "submodules\bgfx\.build\projects\vs2022\bgfx.sln" -consoleLoggerParameters:ShowTimestamp;Summary -verbosity:minimal -maxCpuCount -p:Platform=x64 -p:Configuration=Debug /m
echo ErrorLevel:%ERRORLEVEL%
IF %ERRORLEVEL% EQU 0 (
   echo Build successful!
) else (
   echo Build failed!
)
echo Building BGFX Release in Visual Studio 2022
call "%MSBUILD%" "submodules\bgfx\.build\projects\vs2022\bgfx.sln" -consoleLoggerParameters:ShowTimestamp;Summary -verbosity:minimal -maxCpuCount -p:Platform=x64 -p:Configuration=Release /m
echo ErrorLevel:%ERRORLEVEL%
IF %ERRORLEVEL% EQU 0 (
   echo Build successful!
) else (
   echo Build failed!
)
) else (
echo Visual Studio 2022 not found! Open 'submodules\bgfx\.build\projects\vs2022\bgfx.sln' yourself and build it with your own version (NOTE you'll need to change vs2022 above to your installed version)
)
