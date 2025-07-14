<#
.SYNOPSIS

A script to register the necessary Azure Update Manager (AUM) resource providers in a specified Azure subscription.

.DESCRIPTION

A script to register the necessary Azure Update Manager (AUM) resource providers in a specified Azure subscription.
The script will do all of the following:

Register the Microsoft.Compute resource provider if not registered.
Register the Microsoft.HybridCompute resource provider if not registered.
Register the Microsoft.Maintenance resource provider if not registered.

.NOTES

Filename:       Register-AUM-resource-providers-in-a-specified-subscription.ps1
Created:        08/07/2025
Last modified:  08/07/2025
Author:         Wim Matthyssen
Version:        1.0
PowerShell:     Azure PowerShell and Azure Cloud Shell
Requires:       PowerShell Az (v10.4.1)
Action:         Change variables were needed to fit your needs.
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE

Connect-AzAccount
Get-AzTenant (if not using the default tenant)
Set-AzContext -tenantID "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx" (if not using the default tenant)
.\Create-Azure-Attestation-provider-in-a-specified-subscription.ps1 -SubscriptionName <"your Azure subscription name here"> 

-> .\Register-AUM-resource-providers-in-a-specified-subscription -SubscriptionName sub-prd-myh-arc-infra-03

.LINK


#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Parameters

param(
    # $subscriptionName -> Name of the Azure Subscription
    [parameter(Mandatory =$true)][ValidateNotNullOrEmpty()] [string] $subscriptionName
)

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$providerNameSpaceCompute = "Microsoft.Compute"
$providerNameSpaceHybridCompute = "Microsoft.HybridCompute"
$providerNameSpaceMaintenance = "Microsoft.Maintenance"

Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"} | Out-Null 
$foregroundColor1 = "Green"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Remove the breaking change warning messages

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true | Out-Null
Update-AzConfig -DisplayBreakingChangeWarning $false | Out-Null
$warningPreference = "SilentlyContinue"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script started

Write-Host ($writeEmptyLine + "# Script started. Without errors, it can take up to 2 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Change the current context to the specified subscription

$subName = Get-AzSubscription | Where-Object {$_.Name -like $subscriptionName}

Set-AzContext -SubscriptionId $subName.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# Specified subscription in current tenant selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Register the required Azure resource providers in the current subscription context, if not yet registered

# Register Microsoft.Compute resource provider
Register-AzResourceProvider -ProviderNamespace $providerNameSpaceCompute  | Out-Null

# Register Microsoft.HybridCompute resource provider
Register-AzResourceProvider -ProviderNamespace $providerNameSpaceHybridCompute | Out-Null

# Register Microsoft.Maintenance resource provider
Register-AzResourceProvider -ProviderNamespace $providerNameSpaceMaintenance | Out-Null

Write-Host ($writeEmptyLine + "# All required resource providers for AUM are currently registering or have already registered" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
