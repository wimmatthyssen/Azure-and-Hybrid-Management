<#

.SYNOPSIS

A script used to find all Azure classic subscription administrators from all Azure Subscriptions in an Azure tenant.

.DESCRIPTION

A script used to find all Azure classic subscription administrators from all Azure Subscriptions in an Azure tenant.

The script will do all of the following:

Remove the breaking change warning messages.
Get all Azure subscriptions and store them in a variable.
Get and list all Azure classic subscription administrators for each subscription.

.NOTES

Filename:       Get-all-Azure-classic-subscription-administrators.ps1
Created:        20/03/2024
Last modified:  20/03/2024
Author:         Wim Matthyssen
Version:        1.0
PowerShell:     Azure PowerShell and Azure Cloud Shell
Requires:       PowerShell Az (v10.4.1)
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "as is" with no warranties.

.EXAMPLE

Connect-AzAccount
Get-AzTenant (if not using the default tenant)
Set-AzContext -tenantID "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx" (if not using the default tenant)
.\Get-all-Azure-classic-subscription-administrators.ps1

.LINK

https://wmatthyssen.com/2024/03/21/list-azure-classic-subscription-administrators-via-the-azure-portal-or-via-an-azure-powershell-script/
#>


## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

# Time, colors, and formatting
Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"} | Out-Null 
$foregroundColor1 = "Green"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Remove the breaking change warning messages

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true | Out-Null
Update-AzConfig -DisplayBreakingChangeWarning $false | Out-Null
$warningPreference = "SilentlyContinue"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script started

Write-Host ($writeEmptyLine + "# Script started. Without errors, it takes up to 1 minute to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Get all Azure subscriptions and store them in a variable

$subscriptions = Get-AzSubscription

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Get and list all Azure classic subscription administrators for each subscription

foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    $classicAdmins = Get-AzRoleAssignment -IncludeClassicAdministrators | Where-Object {$_.RoleDefinitionName -like "*ServiceAdministrator*" -or $_.RoleDefinitionName -like "*CoAdministrator*"}
    Write-Output "Subscription: $($sub.Name) - $($sub.Id)"
    if ($classicAdmins) {
        foreach ($admin in $classicAdmins) {
            Write-Host ($writeEmptyLine + "# Classic Administrator: $($admin.SignInName)" + $writeSeperatorSpaces + $currentTime)`
            -foregroundcolor $foregroundColor2 $writeEmptyLine 
            #Write-Output "Classic Administrator: $($admin.SignInName)" -foregroundcolor $foregroundColor2
        }
    } else {
        Write-Host ($writeEmptyLine + "# No classic administrators found" + $writeSeperatorSpaces + $currentTime)`
        $writeEmptyLine 
        #Write-Output "No classic administrators found."
    }
    Write-Output ""
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ("# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
