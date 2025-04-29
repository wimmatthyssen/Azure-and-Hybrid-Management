<#
.SYNOPSIS

A script used to enable "Receive updates for other Microsoft products" on Windows Server 2019, 2022, or 2025.

.DESCRIPTION

A script used to enable "Receive updates for other Microsoft products" on Windows Server 2019, 2022, or 2025.
This script will do all of the following:

Check if PowerShell is running as Administrator, otherwise exit the script.
Enable "Receive updates for other Microsoft products". 
Check if "Receive updates for other Microsoft products" is enabled.

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
-foregroundcolorv $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Enable "Receive updates for other Microsoft products" 

$ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"

# Add the Microsoft Update service
# 7 = Microsoft Update(enables updates for other Microsoft products)
$ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "")

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if "Receive updates for other Microsoft products" is enabled

# Check if the service is registered
$msUpdateService = $ServiceManager.GetServices() | Where-Object { $_.ServiceID -eq "7971f918-a847-4430-9279-4a52d1efe18d" }

if ($msUpdateService) {
   Write-Host ($writeEmptyLine + "# The setting 'Receive updates for other Microsoft products' is enabled." + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor2 $writeEmptyLine
} else {
   Write-Host ($writeEmptyLine + "# The setting 'Receive updates for other Microsoft products' is NOT enabled." + $writeSeperatorSpaces + $currentTime)`
   -foregroundcolor $foregroundColor3 $writeEmptyLine 
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




