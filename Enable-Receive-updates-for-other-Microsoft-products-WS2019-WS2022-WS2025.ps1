<#
.SYNOPSIS

A script used to enable "Receive updates for other Microsoft products" on Windows Server 2019, 2022, or 2025.

.DESCRIPTION

A script used to enable "Receive updates for other Microsoft products" on Windows Server 2019, 2022, or 2025.
This script will do all of the following:

Check if PowerShell is running as Administrator, otherwise exit the script.
Enable "Receive updates for other Microsoft products". 
Register the Microsoft Update service.
Check for new updates

.NOTES

File Name:     Enable-Receive-updates-for-other-Microsoft-products-WS2019-WS2022-WS2025.ps1
Created:       29/04/2025
Last Modified: 29/04/2025
Author:        Wim Matthyssen
PowerShell:    Version 5.1 or later
Requires:      -RunAsAdministrator
OS Support:    Windows Server 2019, 2022, and 2025
Version:       1.0
Note:          Update variables as needed to fit your environment
Disclaimer:    This script is provided "As Is" without any warranties.

.EXAMPLE

.\Enable-Receive-updates-for-other-Microsoft-products-WS2019-WS2022-WS2025.ps1

.LINK

https://wmatthyssen.com/2025/04/07/powershell-script-bginfo-deployment-script-for-windows-server-2025/ 
#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$registryPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
$registryValueName = "AllowMUUpdateService"

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Green"
$foregroundColor2 = "Yellow"
$foregroundColor3 = "Red"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if PowerShell is running as Administrator, otherwise exit the script

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
   Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor3 $writeEmptyLine
    exit
}
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script started

Write-Host ($writeEmptyLine + "# Script started. Without errors, it can take up to 1 minute to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Enable "Receive updates for other Microsoft products" 

# Check if the registry path exists
if (Test-Path $registryPath) {
    # Set the registry value to explicitly enable the setting
    Set-ItemProperty -Path $registryPath -Name $registryValueName -Value 1 -ErrorAction SilentlyContinue
    Write-Host ($writeEmptyLine + "# The setting 'Receive updates for other Microsoft products' has been enabled" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor2 $writeEmptyLine 
} else {
    # Create the registry path and set the value if it doesn't exist
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name $registryValueName -Value 1 -PropertyType DWORD -Force | Out-Null
    Write-Host ($writeEmptyLine + "# The registry path and setting for 'Receive updates for other Microsoft products' have been created and enabled" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor2 $writeEmptyLine 
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Register the Microsoft Update service

$ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager" 
$ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "") | Out-Null

Write-Host ($writeEmptyLine + "# Microsoft Update service has been registered successfully" + $writeSeperatorSpaces + $currentTime)` -foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check for new updates

Write-Host ($writeEmptyLine + "# Checking for new updates..." + $writeSeperatorSpaces + $currentTime)` -foregroundcolor $foregroundColor2 $writeEmptyLine

try {
    $updateSession = New-Object -ComObject "Microsoft.Update.Session"
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0")

    if ($searchResult.Updates.Count -gt 0) {
        Write-Host ($writeEmptyLine + "# New updates are available:" + $writeSeperatorSpaces + $currentTime)` -foregroundcolor $foregroundColor2 $writeEmptyLine
        foreach ($update in $searchResult.Updates) {
            Write-Host ("- " + $update.Title) -foregroundcolor $foregroundColor2
        }
    } else {
        Write-Host ($writeEmptyLine + "# No new updates are available." + $writeSeperatorSpaces + $currentTime)` -foregroundcolor $foregroundColor2 $writeEmptyLine
    }
} catch {
    Write-Host ($writeEmptyLine + "# An error occurred while checking for updates: $_" + $writeSeperatorSpaces + $currentTime)` -foregroundcolor $foregroundColor3 $writeEmptyLine
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
