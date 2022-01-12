<#
.SYNOPSIS

A script used to create an Azure Monitor action group.

.DESCRIPTION

A script used to used to create an Azure Monitor action group. 
The Action Type used in this script is Email.

.NOTES

Filename:       Create-Azure-Monitor-Action-Group.ps1
Created:        26/11/2019
Last modified:  12/01/2022
Author:         Wim Matthyssen
PowerShell:     Azure Cloud Shell or Azure PowerShell
Version:        Install latest Azure Powershell modules
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE

.\Create-Azure-Monitor-Action-Group.ps1

.LINK

https://wmatthyssen.com/2019/11/26/create-an-azure-monitor-action-group-with-azure-powershell/
#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$resourceProviderNamespace = "Microsoft.AlertsManagement"

$rgActionGroup = #<your Action Group rg here> The name of the resource group in which the action group is saved. Example: "rg-hub-myh-management"
$actionGroupName = #<your Action Group name here> The name of the Action Group. Example: "ag-hub-myh-admin"
$actionGroupShortName = #<your Action Group display name here> The name used when notifications are sent using this group, max 12 characters long. Example: "ag-admin"
$emailReceiverName = "emailreceiver"
$emailAddress = #<your email address here> The email address you want to use. Example: "test@demo.com"

$tagSpokeKey = #<your environment tag key here> The environment tag key you want to use. Example:"env"
$tagSpokeValue = #<your environment tag value here> The environment tag value you want to use. Example:"hub"
$tagCostCenterKey  = #<your costCenter tag key here> The costCenter tag key you want to use. Example:"costCenter"
$tagCostCenterValue = #<your costCenter tag value here> The costCenter tag value you want to use. Example: "it"
$tagBusinessCriticalityKey  = #<your businessCriticality tag key here> The businessCriticality tag key you want to use. Example:"costCenter"
$tagBusinessCriticalityValue = #<your businessCriticality tag value here> The businessCriticality tag value you want to use. Example: "critical"
$tagPurposeKey  = #<your purpose tag key here> The purpose tag key you want to use. Example:"purpose"
$tagPurposeValue = #<your purpose tag value here> The purpose tag value you want to use. Example:"monitor"

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if PowerShell runs as Administrator (when not running from Cloud Shell), otherwise exit the script

if ($PSVersionTable.Platform -eq "Unix") {
    Write-Host ($writeEmptyLine + "# Running in Cloud Shell" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    
    ## Start script execution    
    Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 6 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine 
} else {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        ## Check if running as Administrator, otherwise exit the script
        if ($isAdministrator -eq $false) {
        Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine
        exit
        }
        else {

        ## If running as Administrator, start script execution    
        Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 6 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine 
        }
}

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Suppress breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Register required Azure resource provider

Register-AzResourceProvider -ProviderNamespace $resourceProviderNamespace

Write-Host ($writeEmptyLine + "# Required resource provider $resourceProviderNamespace registerd" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a new Action Group Email receiver in memory 

$emailReceiver = New-AzActionGroupReceiver -Name $emailReceiverName -EmailReceiver -EmailAddress $emailAddress

Write-Host ($writeEmptyLine + "# Action Group Receiver $emailReceiverName saved in memory" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a new Action Group

# Set tags (Key,Value)
$tag = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.String]"
$tag.Add($tagSpokeKey,$tagSpokeValue)
$tag.Add($tagCostCenterKey,$tagCostCenterValue)
$tag.Add($tagBusinessCriticalityKey,$tagBusinessCriticalityValue)
$tag.Add($tagPurposeKey,$tagPurposeValue)

Set-AzActionGroup -Name $actionGroupName -ResourceGroup $rgActionGroup -ShortName $actionGroupShortName -Receiver $emailReceiver -Tag $tag

Write-Host ($writeEmptyLine + "# Action Group $actionGroupName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
