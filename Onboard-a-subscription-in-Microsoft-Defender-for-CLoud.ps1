<#
.SYNOPSIS

A script used to onboard an Azure subscription in Microsoft Defender for Cloud.

.DESCRIPTION

A script used to onboard an Azure subscription in Microsoft Defender for Cloud.
The script will do all of the following:

Check if the PowerShell window is running as administrator (when not running from Cloud Shell); otherwise, the Azure PowerShell script will be exited.
Remove the breaking change warning messages.
Change the current context to the subscription holding the central Log Analytics workspace.
Save the Log Analytics workspace as a variable.
Change the current context to the specified subscription.
Register the required resource providers if they are not already registered. Registration may take up to 10 minutes.
Enable Defender Plans.
Configure the Log Analytics workspace to which the agents will report.
Auto-provision installation of the Log Analytics agent on your Azure VMs.
Configure security contacts.

.NOTES

Filename:       Onboard-a-subscription-in-Microsoft-Defender-for-Cloud.ps1
Created:        12/02/2023
Last modified:  12/02/2023
Author:         Wim Matthyssen
Version:        1.0
PowerShell:     Azure PowerShell and Azure Cloud Shell
Requires:       PowerShell Az (v5.9.0)
Action:         Change variables as needed to fit your needs.
Disclaimer:     This script is provided "as is" with no warranties.

.EXAMPLE

Connect-AzAccount
Get-AzTenant (if not using the default tenant)
Set-AzContext -tenantID "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx" (if not using the default tenant)
.\Onboard-a-subscription-in-Microsoft-Defender-for-Cloud.ps1 <"your Azure subscription name here">

-> .\Onboard-a-subscription-in-Microsoft-Defender-for-Cloud.ps1 sub-hub-myh-identity-01

.LINK


#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Parameters

param(
    # $subscriptionName -> Name of the Azure Subscription
    [parameter(Mandatory =$true)][ValidateNotNullOrEmpty()] [string] $subscriptionName
)

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$companyShortName ="myh"
$abbraviationLogAnalytics = "law"
$inventoryNumbering = 1

$logAnalyticsWorkSpaceName = $abbraviationLogAnalytics + "-" + "hub" + "-" + $companyShortName + "-" + $inventoryNumbering.ToString("D2")

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if the PowerShell window is running as administrator (when not running from Cloud Shell); otherwise, the Azure PowerShell script will be exited

if ($PSVersionTable.Platform -eq "Unix") {
    Write-Host ($writeEmptyLine + "# Running in Cloud Shell" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    
    ## Start script execution    
    Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will take around 2 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine 
} else {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        ## Check if running as Administrator, otherwise exit the script
        if ($isAdministrator -eq $false) {
        Write-Host ($writeEmptyLine + "# Please run PowerShell as an administrator" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine
        Start-Sleep -s 3
        exit
        }
        else {

        ## If running as an administrator, start script execution    
        Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will take around 2 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine 
        }
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Remove the breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Change the current context to the subscription holding the central Log Analytics workspace.

# Change subscripiton type name --> example: *management*
$subNameManagement = Get-AzSubscription | Where-Object {$_.Name -like "*your subscripiton type name here*"}

Set-AzContext -SubscriptionId $subNameManagement.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# The subscription holding the central Log Analytics workspace is selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Save the Log Analytics workspace as a variable

$workSpace = Get-AzOperationalInsightsWorkspace | Where-Object Name -Match $logAnalyticsWorkSpaceName

Write-Host ($writeEmptyLine + "# Log Analytics workspace variable created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Change the current context to the specified subscription

$subName = Get-AzSubscription | Where-Object {$_.Name -like $subscriptionName}

Set-AzContext -SubscriptionId $subName.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# Specified subscription in current tenant selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Register the required resource providers if they are not already registered. Registration may take up to 10 minutes

Register-AzResourceProvider -ProviderNamespace 'Microsoft.Security'  | Out-Null
Register-AzResourceProvider -ProviderNamespace 'Microsoft.PolicyInsights' | Out-Null

Write-Host ($writeEmptyLine + "# Required resource providers registered" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Enable Defender Plans

# Defender for Servers Plan 2
Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard" | Out-Null

# Defender for App Service
Set-AzSecurityPricing -Name "AppServices" -PricingTier "Standard" | Out-Null

# Defender for Containers
Set-AzSecurityPricing -Name "Containers" -PricingTier "Standard" | Out-Null

# Defender for Key Vault
Set-AzSecurityPricing -Name "KeyVaults" -PricingTier "Standard" | Out-Null

# Defender for Azure SQL
Set-AzSecurityPricing -Name "SqlServers" -PricingTier "Standard" | Out-Null

# Defender for SQL servers on machines
Set-AzSecurityPricing -Name "SqlServerVirtualMachines" -PricingTier "Standard" | Out-Null

# Defender for open-source relational databases
Set-AzSecurityPricing -Name "OpenSourceRelationalDatabases" -PricingTier "Standard" | Out-Null

# Defender for Azure Cosmos DB
Set-AzSecurityPricing -Name "CosmosDBs" -PricingTier "Standard" | Out-Null

# Defender for Storage
Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Standard" | Out-Null

# Defender for Resource Manager
Set-AzSecurityPricing -Name "ARM" -PricingTier "Standard" | Out-Null

# Defender for DNS
Set-AzSecurityPricing -Name "DNS" -PricingTier "Standard" | Out-Null

# Cloud Security Posture Management (CSPM) ## PREVIEW ##
# Set-AzSecurityPricing -Name "CloudPosture" -PricingTier "Standard" | Out-Null

Write-Host ($writeEmptyLine + "# Specified Defender Plans enabled" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Configure the Log Analytics workspace to which the agents will report

Set-AzSecurityWorkspaceSetting -Name "default" -Scope "/subscriptions/ $($subName.Id)" -WorkspaceId $workSpace.ResourceId | Out-Null

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Auto-provision installation of the Log Analytics agent on your Azure VMs

Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision | Out-Null

Write-Host ($writeEmptyLine + "# Auto-provision installation of the Log Analytics agent configured" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Configure security contacts

# Change -Name and -Email --> example: -Name "azureadmin" -Email "azure.admin@example.com"
Set-AzSecurityContact -Name "<your first security contact name here>" -Email "<your first email address here>" -AlertAdmin -NotifyOnAlert

# Change -Name and -Email --> example: -Name "azuresupport" -Email "azure.support@example.com"
Set-AzSecurityContact -Name "<your second security contact name here>" -Email "<your second email address here>" -AlertAdmin -NotifyOnAlert 

Write-Host ($writeEmptyLine + "# Security contact details are defined" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

