@echo off
REM SetupComplete.cmd - Runs after Windows installation completes
REM This is an alternative/backup to FirstLogonCommands

echo === Windows Server 2019 Post-Install Setup === >> C:\Setup\SetupComplete.log
echo %date% %time% >> C:\Setup\SetupComplete.log

REM Create setup directory
if not exist C:\Setup mkdir C:\Setup

REM Copy scripts from mounted media if available
if exist D:\Setup\Configure-ADDS.ps1 (
    copy /Y D:\Setup\Configure-ADDS.ps1 C:\Setup\ >> C:\Setup\SetupComplete.log 2>&1
)

REM Log completion
echo SetupComplete.cmd finished >> C:\Setup\SetupComplete.log
