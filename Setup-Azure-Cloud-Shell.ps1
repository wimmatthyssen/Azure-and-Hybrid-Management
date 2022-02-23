<#

.SYNOPSIS

A script used to setup Cloud Shell for an Azure environment.

.DESCRIPTION

A script used to setup Cloud Shell for an Azure environment.
The script will first change the current context to use the management subscription.
Then it will store a set of specified tags into a hash table.
Next it will create a resource group for Cloud Shell resources, if it not already exists.
Then it will create a general purpose v2 storage account with specific configuration settings (like minimum TLS version set to 1.2, allow public access disabled), if it not already exists.
And at the end it will create an Azure File Share with a size of 6 GiB, if it not already exists.

.NOTES

Filename:       Setup-Azure-Cloud-Shell.ps1
Created:        30/07/2020
Last modified:  23/02/2022
Author:         Wim Matthyssen
PowerShell:     PowerShell 5.1; Azure PowerShell
Version:        Install latest Az modules
Action:         Change variables where needed to fit your needs
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE

Connect-AzAccount
Get-AzTenant (if not using the default tenant)
Set-AzContext -tenantID "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx" (if not using the default tenant)
.\Setup-Azure-Cloud-Shell.ps1

.LINK

#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$spoke = "hub"
$location = #<your region here> The used Azure public region. Example: "westeurope"
$purpose = "cloudshell"

$rgStorageSpoke = #<your Azure Cloud Shell rg here> The new Azure resource group in which the new Cloud Shell resources will be created. Example: "rg-hub-myh-storage"
$cloudShellStorageAccount = #<your storage account name here> The name of the storage account used by Cloud Shell  Example: "stlrshubmyhcs"
$storageSkuNameStandardLrs = "Standard_LRS"
$storageAccountType = "StorageV2"
$storageMinimumTlsVersion = "TLS1_2"

$fileShareAccessTier = "TransactionOptimized"
$fileShareQuotaGiB = 6 

$tagSpokeName = #<your environment tag name here> The environment tag name you want to use. Example:"env"
$tagCostCenterName  = #<your costCenter tag name here> The costCenter tag name you want to use. Example:"costCenter"
$tagCostCenterValue = #<your costCenter tag value here> The costCenter tag value you want to use. Example: "it"
$tagBusinessCriticalityName = #<your businessCriticality tag name here> The businessCriticality tag name you want to use. Example:"businessCriticality"
$tagBusinessCriticalityValue = #<your businessCriticality tag value here> The businessCriticality tag value you want to use. Example: "critical"
$tagPurposeName  = #<your purpose tag name here> The purpose tag name you want to use. Example:"purpose"

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
    
    # Start script execution    
    Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 2 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine 
} else {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        # Check if running as Administrator, otherwise exit the script
        if ($isAdministrator -eq $false) {
        Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine
        Start-Sleep -s 3
        exit
        }
        else {

        # If running as Administrator, start script execution    
        Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 2 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine 
        }
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Suppress breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Change the current context to use the management subscription

$subNameManagement = Get-AzSubscription | Where-Object {$_.Name -like "*management*"}
$tenant = Get-AzTenant #current tenant

Set-AzContext -TenantId $tenant.TenantId -SubscriptionId $subNameManagement.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# Management Subscription in current tenant selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Store the specified set of tags in a hash table

$tag = @{$tagSpokeName=$spoke;$tagCostCenterName=$tagCostCenterValue;$tagBusinessCriticalityName=$tagBusinessCriticalityValue;$tagPurposeName =$purpose}

Write-Host ($writeEmptyLine + "# Specified set of tags available to add" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a dedicated resource group for Azure storage resources in the hub (also holds the Cloud Shell Azure Files share) if it not exists  

try {
    Get-AzResourceGroup -Name $rgStorageSpoke -ErrorAction Stop | Out-Null 
} catch {
    New-AzResourceGroup -Name $rgStorageSpoke -Location $location -Tag $tag -Force | Out-Null 
}

Write-Host ($writeEmptyLine + "# Resource group $rgStorageSpoke available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a storage account for Cloud Shell if it not exists

try {
    Get-AzStorageAccount -ResourceGroupName $rgStorageSpoke -Name $cloudShellStorageAccount -ErrorAction Stop | Out-Null 
} catch {
    New-AzStorageAccount -ResourceGroupName $rgStorageSpoke -Name $cloudShellStorageAccount -SkuName $storageSKUNameStandardLRS -Location $location -Kind $storageAccountType `
    -AllowBlobPublicAccess $false -MinimumTlsVersion $storageMinimumTlsVersion -Tag $tag | Out-Null 
}

Write-Host ($writeEmptyLine + "# Storage account $cloudShellStorageAccount created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create an Azure file share for Cloud Shell if it not exists

try {
    Get-AzRmStorageShare -ResourceGroupName $rgStorageSpoke -StorageAccountName $cloudShellStorageAccount -Name $purpose -ErrorAction Stop | Out-Null 
} catch {
    New-AzRmStorageShare -ResourceGroupName $rgStorageSpoke -StorageAccountName $cloudShellStorageAccount -Name $purpose -AccessTier $fileShareAccessTier -QuotaGiB $fileShareQuotaGiB `
    -Metadata $tag | Out-Null 
}

Write-Host ($writeEmptyLine + "# Azure file share $purpose created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
