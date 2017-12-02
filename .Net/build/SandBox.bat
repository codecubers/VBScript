
:: compile SandBox.cs

@echo off

@echo Getting .Net executables locations
call ..\config\exeLocations.bat

@echo Compiling SandBox.exe
%net32%\csc.exe @..\rsp\_common.rsp @..\rsp\SandBox.rsp ..\SandBox.cs

@echo Registering .dll for 32-bit apps
%net32%\regasm.exe /codebase %1 ..\lib\SandBox.dll

@echo. & @echo Registering .dll for 64-bit apps
%net64%\regasm.exe /codebase %1 ..\lib\SandBox.dll
