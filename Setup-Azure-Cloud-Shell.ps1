<#

.SYNOPSIS

A script used to setup Azure Cloud Shell for an Azure environment.

.DESCRIPTION

A script used to setup Azure Cloud Shell for an Azure environment.
The script will first change the current context to use the management subscription.
Then it will store a set of specified tags into a hash table.
Next it will create a resource group for Cloud Shell resources, if it not already exists.
Then it will create a general purpose v2 storage account with specific configuration settings (like minimum TLS version set to 1.2, allow public access disabled), if it not already exists.
And at the end it will create an Azure File Share with a size of 6 GiB, if it not already exists.

.NOTES

Filename:       Setup-Azure-Cloud-Shell.ps1
Created:        30/07/2020
Last modified:  29/07/2022
Author:         Wim Matthyssen
Version:        2.0
PowerShell:     PowerShell 5.1 and Azure PowerShell
Requires:       PowerShell Az (v5.9.0) Module
Action:         Change variables where needed to fit your needs
Disclaimer:     This script is provided "As Is" with no warranties

.EXAMPLE

Connect-AzAccount
Get-AzTenant (if not using the default tenant)
Set-AzContext -tenantID "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx" (if not using the default tenant)
.\Setup-Azure-Cloud-Shell.ps1

.LINK

https://wmatthyssen.com/2022/02/23/setup-azure-cloud-shell-with-azure-powershell/
#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$spoke = "hub"
$region = #<your region here> The used Azure public region. Example: "westeurope"
$purpose = "CloudShell"

$rgStorageSpoke = #<your Azure Cloud Shell rg here> The new Azure resource group in which the new Cloud Shell resources will be created. Example: "rg-hub-myh-storage-01""
$cloudShellStorageAccount = #<your storage account name here> The name of the storage account used by Cloud Shell  Example: "stlrshubmyhcs"
$storageSkuNameStandardLrs = "Standard_LRS"
$storageAccountType = "StorageV2"
$storageMinimumTlsVersion = "TLS1_2"

$fileShareAccessTier = "TransactionOptimized"
$fileShareQuotaGiB = 6 

$tagSpokeName = #<your environment tag name here> The environment tag name you want to use. Example:"Env"
$tagSpokeValue = "$($spoke[0].ToString().ToUpper())$($spoke.SubString(1))"
$tagCostCenterName  = #<your costCenter tag name here> The costCenter tag name you want to use. Example:"CostCenter"
$tagCostCenterValue = #<your costCenter tag value here> The costCenter tag value you want to use. Example: "23"
$tagCriticalityName = #<your businessCriticality tag name here> The businessCriticality tag name you want to use. Example:"Criticality"
$tagCriticalityValue = #<your businessCriticality tag value here> The businessCriticality tag value you want to use. Example: "High"
$tagPurposeName  = #<your purpose tag name here> The purpose tag name you want to use. Example:"Purpose"
$tagPurposeValue = $purpose

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if PowerShell runs as Administrator, otherwise exit the script

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

## Check if running PowerShell as Administrator, otherwise exit the script
if ($isAdministrator -eq $false) {
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    Start-Sleep -s 3
    exit
} else {
    ## If running as Administrator, start script execution    
    Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 1 minute to complete" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine 
    }

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Suppress breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Change the current context to use the Management subscription

$subNameTest = Get-AzSubscription | Where-Object {$_.Name -like "*management*"}
$tenant = Get-AzTenant | Where-Object {$_.Name -like "*$companyShortName*"}

Set-AzContext -TenantId $tenant.TenantId -SubscriptionId $subNameTest.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# Management Subscription in current tenant selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Store the specified set of tags in a hash table

$tags = @{$tagSpokeName=$tagSpokeValue;$tagCostCenterName=$tagCostCenterValue;$tagCriticalityName=$tagCriticalityValue;$tagPurposeName=$tagPurposeValue}

Write-Host ($writeEmptyLine + "# Specified set of tags available to add" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a dedicated resource group for Azure storage resources in the hub (also holds the Cloud Shell Azure Files share) if it not exists  

try {
    Get-AzResourceGroup -Name $rgStorageSpoke -ErrorAction Stop | Out-Null 
} catch {
    New-AzResourceGroup -Name $rgStorageSpoke -Location $region -Force | Out-Null 
}

# Set tags rg storage
Set-AzResourceGroup -Name $rgStorageSpoke -Tag $tags | Out-Null

Write-Host ($writeEmptyLine + "# Resource group $rgStorageSpoke available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a storage account for Cloud Shell if it not exists

try {
    Get-AzStorageAccount -ResourceGroupName $rgStorageSpoke -Name $cloudShellStorageAccount -ErrorAction Stop | Out-Null 
} catch {
    New-AzStorageAccount -ResourceGroupName $rgStorageSpoke -Name $cloudShellStorageAccount -SkuName $storageSKUNameStandardLRS -Location $region -Kind $storageAccountType `
    -AllowBlobPublicAccess $false -MinimumTlsVersion $storageMinimumTlsVersion | Out-Null 
}

# Set tags storage account
Set-AzStorageAccount -ResourceGroupName $rgStorageSpoke -Name $cloudShellStorageAccount -Tag $tags | Out-Null

Write-Host ($writeEmptyLine + "# Storage account $cloudShellStorageAccount created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create an Azure file share for Cloud Shell if it not exists

$fileShareName = "$($purpose.ToString().ToLower())"

try {
    Get-AzRmStorageShare -ResourceGroupName $rgStorageSpoke -StorageAccountName $cloudShellStorageAccount -Name $fileShareName -ErrorAction Stop | Out-Null 
} catch {
    New-AzRmStorageShare -ResourceGroupName $rgStorageSpoke -StorageAccountName $cloudShellStorageAccount -Name $fileShareName -AccessTier $fileShareAccessTier `
    -QuotaGiB $fileShareQuotaGiB | Out-Null 
}

# Set Metadata file share
Update-AzRmStorageShare -ResourceGroupName $rgStorageSpoke -StorageAccountName $cloudShellStorageAccount -Name $fileShareName -Metadata $tags | Out-Null

Write-Host ($writeEmptyLine + "# Azure file share $fileShareName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
