<#
.SYNOPSIS

A script used to install and configure OpenSHH on a Windows Server 2019, 2022, or 2025.

.DESCRIPTION

A script used to install and configure OpenSHH on a Windows Server 2019, 2022, or 2025.
This script will do all of the following:

Check if PowerShell is running as Administrator, otherwise exit the script.
Check if the OS is Windows Server 2025 and set a flag to control script execution.
Install OpenSSH Server if OS is Windows Server 2019 or Windows Server 2022.
Install OpenSSH Client if OS is Windows Server 2019 or Windows Server 2022. 
Start and enable the SSH service.   
Allow OpenSSH through the Windows Firewall.

.NOTES

Filename:       Install-OpenSSH-on-a-Windows-Server-2019-2022-2025.ps1
Created:        02/04/2025
Last modified:  02/04/2025
Author:         Wim Matthyssen
Version:        1.0
PowerShell:     Windows PowerShell (v5.1 or above)
OS:             Windows Server 2019, Windows Server 2022, or Windows Server 2025
Action:         Update variables if needed to fit your environment.
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE

.\Install-OpenSSH-on-a-Windows-Server-2019-2022-2025.ps1 

.LINK


#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

# Dynamic variables - Please change the values if needed to fit your environment.
$firewallRuleName = "OpenSSH-Server-In"  # Variable for the firewall rule name

Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"} | Out-Null
$foregroundColor1 = "Green"
$foregroundColor2 = "Yellow"
$foregroundColor3 = "Red"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script started.

Write-Host ($writeEmptyLine + "# Script started. Without errors, it can take up to 2 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if PowerShell is running as Administrator, otherwise exit the script.

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdministrator -eq $false) 
{
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor3 $writeEmptyLine
    exit
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if the OS is Windows Server 2025 and set a flag to control script execution.

try {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    if ($osInfo.Caption -like "*Windows Server 2025*") {
        Write-Host ($writeEmptyLine + "# OS is Windows Server 2025. Continuing script execution" + $writeSeperatorSpaces + $global:currenttime)`
        -foregroundcolor $foregroundColor2 $writeEmptyLine
        $isWindowsServer2025 = $true
    } else {
        # OS is not Windows Server 2025, continue with the script
        Write-Host ($writeEmptyLine + "# OS is not Windows Server 2025. Continuing script execution" + $writeSeperatorSpaces + $global:currenttime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine
        $isWindowsServer2025 = $false
    }
} catch {
    Write-Host ($writeEmptyLine + "# Failed to retrieve OS information: $($_.Exception.Message)" + $writeSeperatorSpaces + $global:currenttime)`
    -foregroundcolor $foregroundColor3 $writeEmptyLine
    exit
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Install OpenSSH Server if OS is Windows Server 2019 or Windows Server 2022.

if (-not $isWindowsServer2025) {
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop | Out-Null 
        Write-Host ($writeEmptyLine + "# OpenSSH Server installed" + $writeSeperatorSpaces + $global:currenttime)`
        -foregroundcolor $foregroundColor2 $writeEmptyLine
    } catch {
        Write-Host ($writeEmptyLine + "# Failed to install OpenSSH Server: $($_.Exception.Message)" + $writeSeperatorSpaces + $global:currenttime)`
        -foregroundcolor $foregroundColor3 $writeEmptyLine
        exit
    }
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Install OpenSSH Client if OS is Windows Server 2019 or Windows Server 2022.

if (-not $isWindowsServer2025) {
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 -ErrorAction Stop | Out-Null 
        Write-Host ($writeEmptyLine + "# OpenSSH Client installed" + $writeSeperatorSpaces + $global:currenttime)`
        -foregroundcolor $foregroundColor2 $writeEmptyLine
    } catch {
        Write-Host ($writeEmptyLine + "# Failed to install OpenSSH Client: $($_.Exception.Message)" + $writeSeperatorSpaces + $global:currenttime)`
        -foregroundcolor $foregroundColor3 $writeEmptyLine
        exit
    }
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Start and enable the SSH service.

try {
    # Start the SSH service
    Start-Service sshd
    # Set the SSH service to start automatically with Windows
    Set-Service -Name sshd -StartupType Automatic
    Write-Host ($writeEmptyLine + "# SSH service started and set to automatic" + $writeSeperatorSpaces + $global:currenttime)`
    -foregroundcolor $foregroundColor2 $writeEmptyLine
} catch {
    Write-Host ($writeEmptyLine + "# Failed to start or configure SSH service: $($_.Exception.Message)" + $writeSeperatorSpaces + $global:currenttime)`
    -foregroundcolor $foregroundColor3 $writeEmptyLine
    exit
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Allow OpenSSH through the Windows Firewall.

try {
    # Check if the firewall rule already exists
    $firewallRule = Get-NetFirewallRule -Name $firewallRuleName -ErrorAction SilentlyContinue

    if ($null -eq $firewallRule) {
        # Rule does not exist, create it
        New-NetFirewallRule -Name $firewallRuleName -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
        Write-Host ($writeEmptyLine + "# Windows Firewall rule created and configured for OpenSSH" + $writeSeperatorSpaces + $global:currenttime)`
        -foregroundcolor $foregroundColor2 $writeEmptyLine
    } else {
        # Rule already exists
        Write-Host ($writeEmptyLine + "# Windows Firewall rule already exists and is configured for OpenSSH" + $writeSeperatorSpaces + $global:currenttime)`
        -foregroundcolor $foregroundColor2 $writeEmptyLine
    }
} catch {
    Write-Host ($writeEmptyLine + "# Failed to configure Windows Firewall for OpenSSH: $($_.Exception.Message)" + $writeSeperatorSpaces + $global:currenttime)`
    -foregroundcolor $foregroundColor3 $writeEmptyLine
    exit
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed.

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------