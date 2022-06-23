<#
.SYNOPSIS

A script used to create an Azure Monitor action group.

.DESCRIPTION

A script used to used to create an Azure Monitor action group with the Email action type.
This script will do all of the following:

Check if the PowerShell window is running as Administrator (which is a requirement), otherwise the Azure PowerShell script will be exited.
Suppress breaking change warning messages.
Store the specified set of tags in a hash table.
Set and add tags with the specified key/value pairs into the proper data type (dictionary object instead of a hash table) to be able to use them with an Action Group.
Create a resource group for the action group resource, if it not already exists. Add specified tags.
Create a new action group Email receiver in memory.
Create a new or update the existing action group.
Lock the Action Group resource group with a CanNotDelete lock.

.NOTES

Filename:       Create-Azure-Monitor-Action-Group.ps1
Created:        26/11/2019
Last modified:  23/06/2022
Author:         Wim Matthyssen
Version:        2.0
PowerShell:     Azure Cloud Shell or Azure PowerShell
Version:        Install latest Azure Powershell modules
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE

Connect-AzAccount
.\Create-Azure-Monitor-Action-Group.ps1

.LINK

https://wmatthyssen.com/2019/11/26/create-an-azure-monitor-action-group-with-azure-powershell/
#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$spoke = "hub"
$purpose = "monitor"

$rgActionGroup = #<your action group rg here> The name of the resource group in which the action group is saved. Example: "rg-hub-myh-management"
$actionGroupName = #<your action group name here> The name of the action group. Example: "ag-hub-myh-admin"
$actionGroupShortName = #<your action group display name here> The name used when notifications are sent using this group, max 12 characters long. Example: "ag-admin"
$emailReceiverName = "emailreceiver"
$emailAddress = #<your email address here> The email address you want to use. Example: "test@demo.com"

$tagSpokeName = #<your environment tag name here> The environment tag name you want to use. Example:"Env"
$tagSpokeValue = "$($spoke[0].ToString().ToUpper())$($spoke.SubString(1))"
$tagCostCenterName  = #<your costCenter tag name here> The costCenter tag name you want to use. Example:"CostCenter"
$tagCostCenterValue = #<your costCenter tag value here> The costCenter tag value you want to use. Example: "23"
$tagCriticalityName = #<your businessCriticality tag name here> The businessCriticality tag name you want to use. Example:"Criticality"
$tagCriticalityValue = #<your businessCriticality tag value here> The businessCriticality tag value you want to use. Example: "High"
$tagPurposeName  = #<your purpose tag name here> The purpose tag name you want to use. Example:"Purpose"
$tagPurposeValue = "$($purpose[0].ToString().ToUpper())$($purpose.SubString(1))" 

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if PowerShell runs as Administrator (when not running from Cloud Shell), otherwise exit the script

if ($PSVersionTable.Platform -eq "Unix") {
    Write-Host ($writeEmptyLine + "# Running in Cloud Shell" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    
    ## Start script execution    
    Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 1 minute to complete" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine 
} else {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        ## Check if running as Administrator, otherwise exit the script
        if ($isAdministrator -eq $false) {
        Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine
        Start-Sleep -s 3
        exit
        }
        else {

        ## If running as Administrator, start script execution    
        Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 1 minute to complete" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine 
        }
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Suppress breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Store the specified set of tags in a hash table

$tags = @{$tagSpokeName=$tagSpokeValue;$tagCostCenterName=$tagCostCenterValue;$tagCriticalityName=$tagCriticalityValue;$tagPurposeName=$tagPurposeValue}

Write-Host ($writeEmptyLine + "# Specified set of tags available to add" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Set and add tags with the specified key/value pairs into the proper data type (dictionary object instead of a hash table) to be able to use them with an Action Group

$tagsActionGroup = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.String]"
$tagsActionGroup.Add($tagSpokeName,$tagSpokeValue)
$tagsActionGroup.Add($tagCostCenterName,$tagCostCenterValue)
$tagsActionGroup.Add($tagCriticalityName,$tagCriticalityValue)
$tagsActionGroup.Add($tagPurposeName,$tagPurposeValue)

Write-Host ($writeEmptyLine + "# Tags set into the proper data type" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a resource group for the action group resource, if it not already exists. Add specified tags

try {
    Get-AzResourceGroup -Name $rgActionGroup -ErrorAction Stop | Out-Null
} catch {
    New-AzResourceGroup -Name $rgActionGroup.ToLower() -Location $region -Force | Out-Null
}

# Set tags Bastion resource group
Set-AzResourceGroup -Name $rgActionGroup -Tag $tags | Out-Null

Write-Host ($writeEmptyLine + "# Resource group $rgActionGroup available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a new action group Email receiver in memory 

$email1 = New-AzActionGroupReceiver -Name $emailReceiverName -EmailReceiver -EmailAddress $emailAddress 

Write-Host ($writeEmptyLine + "# Action Group Receiver $emailReceiverName saved in memory" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a new or update the existing action group

Set-AzActionGroup -Name $actionGroupName -ResourceGroup $rgActionGroup -ShortName $actionGroupShortName -Receiver $email1 -Tag $tagsActionGroup | Out-Null 

Write-Host ($writeEmptyLine + "# Action Group $actionGroupName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Lock the Action Group resource group with a CanNotDelete lock

$lock = Get-AzResourceLock -ResourceGroupName $rgActionGroup

if ($null -eq $lock){
    New-AzResourceLock -LockName DoNotDeleteLock -LockLevel CanNotDelete -ResourceGroupName $rgActionGroup -LockNotes "Prevent $rgActionGroup from deletion" -Force | Out-Null
    } 

Write-Host ($writeEmptyLine + "# Resource group $rgActionGroup locked" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
