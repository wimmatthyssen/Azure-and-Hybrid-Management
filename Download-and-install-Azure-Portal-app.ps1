<#
.SYNOPSIS
 
A script used to download and install the Microsoft Azure Portal app.
 
.DESCRIPTION
 
A script used to download the Azure Portal app on a Windows Server 2016/2019/2022 or Windows 10/11. 
The .exe file will be downloaded in the Azure Portal app folder under the Temp folder. 
After installation the Azure Portal app folder and the .exe file will be deleted. 
 
.NOTES
 
Filename:       Download-and-install-Azure-Portal-app.ps1
Created:        02/01/2020
Last modified:  11/01/2020
Author:         Wim Matthyssen
OS:             Windows Server 2016/2019/2022 or Windows 10/11        
PowerShell:     5.1
Requires:       -RunAsAdministrator
OS:             Windows 10, Windows 11, Windows Server 2016, Windows Server 2019 and Windows Server 2022
Version:        2.0
Action:         Change variables were needed to fit your needs.
Disclaimer:     This script is provided "As Is" with no warranties.
 
.EXAMPLE
 
Download-and-install-Azure-Portal-app.ps1
 
.LINK
 
https://wmatthyssen.com/2020/01/02/download-and-install-the-azure-portal-app-with-powershell/
#>
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Variables

$tempFolderName = "Temp"
$tempFolder = "C:\" + $tempFolderName +"\"
$itemType = "Directory"
$azurePortalAppFolderName = "Azure Portal app"
$tempAzurePortalAppFolder = $tempFolder + $azurePortalAppFolderName
$azurePortalAppUrl = "https://portal.azure.com/app/Download?acceptLicense=true"
$azurePortalAppExe = "AzurePortalInstaller.exe"
$azurePortalAppPath = $tempAzurePortalAppFolder + "\" + $azurePortalAppExe

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if running as Administrator, otherwise close the PowerShell window

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdministrator -eq $false) {
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    Start-Sleep -s 5
    exit
}
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Start script execution

Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 1 minute to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create C:\Temp folder if not exists

If(!(test-path $tempFolder))
{
New-Item -Path "C:\" -Name $tempFolderName -ItemType $itemType -Force | Out-Null
}

Write-Host ($writeEmptyLine + "# $tempFolderName folder available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Create Azure Portal app folder in C:\Temp if not exists
 
If(!(test-path $tempAzurePortalAppFolder))
{
New-Item -Path $tempFolder -Name $azurePortalAppFolderName -ItemType $itemType | Out-Null
}
  
Write-Host ($writeEmptyLine + "# $azurePortalAppFolderName folder available $tempFolderName folder" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Download the Azure Portal app to Temp folder
 
(New-Object System.Net.WebClient).DownloadFile($azurePortalAppUrl, $azurePortalAppPath)
 
Write-Host ($writeEmptyLine + "# $azurePortalAppExe available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Install the Azure Portal app
 
& $azurePortalAppPath
 
Write-Host ($writeEmptyLine + "# The $AzurePortalAppFolderName is installed, you can now logon with your credentials" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Remove AzurePortalInstaller.exe file and Azure Portal app folder from Temp folder after installation
 
Start-Sleep 3
Get-ChildItem -Path $tempAzurePortalAppFolder -Force -Recurse  | Remove-Item -Force -Recurse
Remove-Item $tempAzurePortalAppFolder -Force -Recurse
 
Write-Host ($writeEmptyLine + "# $azurePortalAppExe and $AzurePortalAppFolderName folder are removed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
