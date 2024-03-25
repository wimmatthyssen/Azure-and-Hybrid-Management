<#
.SYNOPSIS

A script used to create an Azure Automation account with an enabled system-assigned managed identity in a management subscription.

.DESCRIPTION

A script used to create an Azure Automation account with an enabled system-assigned managed identity in a management subscription.
The script will do all of the following:

Remove the breaking change warning messages.
Change the current context to use a management subscription holding your central Log Analytics workspace.

Remove the breaking change warning messages.
Check if the Automation account name follows the naming convention; if not, exit the script.
Change the current context to use a management subscription holding your central Log Analytics workspace.
Save the Log Analytics workspace from the management subscription as a variable.
Change the current context to the specified Azure subscription.
Register the required Azure resource provider (Microsoft.Automation) in the current subscription context, if not yet registered.
Store the specified set of tags in a hash table.
Create a resource group management if one does not already exist. Also, apply the necessary tags to this resource group.
Create the Azure Automation account with a new system-assigned managed identity if it does not exist.
Set specified tags on the Azure Automation account.
Set the log and metrics settings for the Azure Automation account if they don't exist.

.NOTES

Filename:       Create-Azure-Automation-account-management-subscription.ps1
Created:        22/02/2024
Last modified:  22/02/2024
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
.\Create-Azure-Automation-account-management-subscription.ps1 -SubscriptionName <"your Azure subscription name here"> -AzureAutomationAccountName <"your Azure Automation account name here">

.LINK

https://wmatthyssen.com/2022/08/01/azure-powershell-script-create-a-log-analytics-workspace-in-your-management-subscription/
#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Parameters

param(
    # $subscriptionName -> Name of the Azure Subscription
    [parameter(Mandatory =$true)][ValidateNotNullOrEmpty()] [string] $subscriptionName,
    # $azureAutomationAccountName -> Name of the Azure Automation account
    [parameter(Mandatory =$true)][ValidateNotNullOrEmpty()] [string] $azureAutomationAccountName
)

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Variables

$spoke = "hub"
$purpose = "management"
$region = #<your region here> The region which the new Automation account will be created. Example: "westeurope"
$providerNameSpace = "Microsoft.Automation"

$rgNameManagement = #<your management resource group name here> The name of the resource group in which the new Automation account will be created. Example: "rg-hub-myh-management-01"

$logAnalyticsWorkSpaceName = #<your central Log Analytics workspace name here> The name for your central Log Analytics workspace. Example: "law-hub-myh-01"

$automationAccountName = $azureAutomationAccountName.ToLower()
$automationDiagnosticsName = "diag" + "-" + $automationAccountName

$tagSpokeName = #<your environment tag name here> The environment tag name you want to use. Example: "Env"
$tagSpokeValue = "$($spoke[0].ToString().ToUpper())$($spoke.SubString(1))"
$tagCostCenterName  = #<your costCenter tag name here> The costCenter tag name you want to use. Example: "CostCenter"
$tagCostCenterValue = #<your costCenter tag value here> The costCenter tag value you want to use. Example: "23"
$tagCriticalityName = #<your businessCriticality tag name here> The businessCriticality tag name you want to use. Example: "Criticality"
$tagCriticalityValue = #<your businessCriticality tag value here> The businessCriticality tag value you want to use. Example: "High"
$tagPurposeName  = #<your purpose tag name here> The purpose tag name you want to use. Example: "Purpose"
$tagPurposeValue = "$($purpose[0].ToString().ToUpper())$($purpose.SubString(1))"

Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"} | Out-Null 
$foregroundColor1 = "Green"
$foregroundColor2 = "Yellow"
$foregroundColor3 = "Red"
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

## Check if the Automation account name follows the naming convention; if not, exit the script

# Define the regular expression pattern
$pattern = "^aa-(hub|prd|dev|acc|tst)-[a-zA-Z]{3}-\d{2}$"

# Check if the variable matches the pattern
if ($automationAccountName -match $pattern) {
    Write-Host ($writeEmptyLine + "# The typed-in Automation account name follows the naming convention, the script will continue." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine
} else {
    Write-Host ($writeEmptyLine + "# The typed-in Automation account name does nog follow the naming convention, the script will exit." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor3 $writeEmptyLine
Write-Host ($writeEmptyLine + "# Please rerun the script with a name following the naming convention." + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor3 $writeEmptyLine
Start-Sleep -s 3
exit
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Change the current context to use a management subscription holding your central Log Anlytics workspace

# Replace <your subscription purpose name here> with purpose name of your subscription. Example: "*management*"
$subNameManagement = Get-AzSubscription | Where-Object {$_.Name -like "*management*"}

Set-AzContext -SubscriptionId $subNameManagement.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# Management subscription in current tenant selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Save Log Analytics workspace from the management subscription in a variable

$workSpace = Get-AzOperationalInsightsWorkspace | Where-Object Name -Match $logAnalyticsWorkSpaceName

Write-Host ($writeEmptyLine + "# Log Analytics workspace variable created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Change the current context to the specified subscription

$subName = Get-AzSubscription | Where-Object {$_.Name -like $subscriptionName}

Set-AzContext -SubscriptionId $subName.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# Specified subscription in current tenant selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Register the required Azure resource provider (Microsoft.Automation) in the current subscription context, if not yet registered

Register-AzResourceProvider -ProviderNamespace $providerNameSpace | Out-Null

Write-Host ($writeEmptyLine + "# All required resource providers for an Azure Auomation account are currently registering or have already registered" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Store the specified set of tags in a hash table

$tags = @{$tagSpokeName=$tagSpokeValue;$tagCostCenterName=$tagCostCenterValue;$tagCriticalityName=$tagCriticalityValue;$tagPurposeName=$tagPurposeValue}

Write-Host ($writeEmptyLine + "# Specified set of tags available to add" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a resource group management if one does not already exist. Also, apply the necessary tags to this resource group

try {
    Get-AzResourceGroup -Name $rgNameManagement -ErrorAction Stop | Out-Null 
} catch {
    New-AzResourceGroup -Name $rgNameManagement -Location $region -Force | Out-Null   
}

# Save variable tags in a new variable to add tags.
$tagsResourceGroup = $tags

# Set tags rg storage.
Set-AzResourceGroup -Name $rgNameManagement -Tag $tagsResourceGroup | Out-Null

Write-Host ($writeEmptyLine + "# Resource group $rgNameManagement available with tags" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create the Azure Automation account if it does not exist

try {
    Get-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $rgNameManagement -ErrorAction Stop | Out-Null 
} catch {
    New-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $rgNameManagement -Location $region | Out-Null
}

Write-Host ($writeEmptyLine + "# Automation account $automationAccountName available or created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Set specified tags on the Azure Automation account

Set-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $rgNameManagement -Tag $tags | Out-Null

Write-Host ($writeEmptyLine + "# Tags Automation account $automationAccountName set" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Enalbe a system-assigned managed identity for the Azure Automation account

Set-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $rgNameManagement -AssignSystemIdentity | Out-Null

Write-Host ($writeEmptyLine + "# System-assigend managed identity for Automation account $automationAccountName enabled" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Set the log and metrics settings for the Azure Automation account if they don't exist

# Wait 15 seconds to let the Automation account be created if necessary
Start-Sleep -Duration (New-TimeSpan -Seconds 15)

$automationAccount = Get-AzResource -Name $automationAccountName -ResourceGroupName $rgNameManagement

try {
    Get-AzDiagnosticSetting -Name $automationDiagnosticsName -ResourceId ($automationAccount.ResourceId) -ErrorAction Stop | Out-Null
} catch {   
    $metric = @()
    $metric += New-AzDiagnosticSettingMetricSettingsObject -Enabled $true -Category AllMetrics
    $log = @()
    $log += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category JobLogs
    $log += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category JobStreams
    $log += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category DscNodeStatus
    $log += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category AuditEvent
        
    New-AzDiagnosticSetting -Name $automationDiagnosticsName -ResourceId ($automationAccount.ResourceId) -WorkspaceId ($workSpace.ResourceId) -Log $log -Metric $metric | Out-Null
}

Write-Host ($writeEmptyLine + "# Automation account $automationAccountName diagnostic settings set" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Lock the resource group with a CanNotDelete lock

$lock = Get-AzResourceLock -ResourceGroupName $rgNameManagement

if ($null -eq $lock){
    New-AzResourceLock -LockName DoNotDeleteLock -LockLevel CanNotDelete -ResourceGroupName $rgNameManagement -LockNotes "Prevent $rgNameManagement from deletion" -Force | Out-Null
    } 

Write-Host ($writeEmptyLine + "# Resource group $rgNameManagement locked" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
