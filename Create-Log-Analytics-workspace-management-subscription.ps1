<#
.SYNOPSIS

A script used to create a Log Analytics workspace with enabled solutions in a management subscription.

.DESCRIPTION

A script used to create a Log Analytics workspace with enabled solutions in a management subscription.
The script will do all of the following:

Check if the PowerShell window is running as Administrator (when not running from Cloud Shell), otherwise the Azure PowerShell script will be exited.
Suppress breaking change warning messages.
Change the current context to use a management subscription (a subscription with *management* in the subscription name will be automatically selected).
Store a specified set of tags in a hash table.
Create a resource group for Log Analytics if it does not exist. Add specified tags and lock with a CanNotDelete lock.
Create the Log Analytics workspace if it does not exist and add the specified tags.
Save the Log Analytics workspace in a variable.
Save the list of solutions to enable in a variable. 
Add the required solutions to the Log Analytics workspace.
Set the log and metrics settings for the Log Analytics workspace, if they don't exist.

.NOTES

Filename:       Create-Log-Analytics-workspace-management-subscription.ps1
Created:        14/10/2021
Last modified:  18/08/2022
Author:         Wim Matthyssen
Version:        2.1
PowerShell:     Azure PowerShell and Azure Cloud Shell
Requires:       PowerShell Az (v5.9.0)
Action:         Change variables were needed to fit your needs.
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE

Connect-AzAccount
Get-AzTenant (if not using the default tenant)
Set-AzContext -tenantID "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx" (if not using the default tenant)
.\Create-Log-Analytics-workspace-management-subscription.ps1

.LINK

https://wmatthyssen.com/2022/08/01/azure-powershell-script-create-a-log-analytics-workspace-in-your-management-subscription/
#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$companyShortName = #"<your company short name here>" The three-letter abbreviation of your company name here. Example: "myh"
$spoke = "hub"
$abbraviationManagement = "management"
$region = #<your region here> The used Azure public region. Example: "westeurope"

$rgLogAnalyticsWorkspaceName = #<your Log Analytics rg name here> The name of the resource group in which the new Log Analytics resources will be created. Example: "rg-hub-myh-management-01"
$LogAnalyticsWorkspaceName = #<your Log Analytics workspace name here> The name for your Log Analytics workspace. Example: "law-hub-myh-01"
$LogAnalyticsWorkspaceSku = "pergb2018"
$LogAnalyticsDiagnosticsName = #<your Log Analytics Diagnostics settings name here> The name of the new diagnostic settings for your Log Analytics workspace. Example: "diag-law-hub-myh-01"

$tagSpokeName = #<your environment tag name here> The environment tag name you want to use. Example: "Env"
$tagSpokeValue = "$($spoke[0].ToString().ToUpper())$($spoke.SubString(1))"
$tagCostCenterName  = #<your costCenter tag name here> The costCenter tag name you want to use. Example: "CostCenter"
$tagCostCenterValue = #<your costCenter tag value here> The costCenter tag value you want to use. Example: "23"
$tagCriticalityName = #<your businessCriticality tag name here> The businessCriticality tag name you want to use. Example: "Criticality"
$tagCriticalityValue = #<your businessCriticality tag value here> The businessCriticality tag value you want to use. Example: "High"
$tagPurposeName  = #<your purpose tag name here> The purpose tag name you want to use. Example: "Purpose"
$tagPurposeValue = "$($abbraviationManagement[0].ToString().ToUpper())$($abbraviationManagement.SubString(1))"

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

## Change the current context to use a management subscription

$subNameManagement = Get-AzSubscription | Where-Object {$_.Name -like "*management*"}

Set-AzContext -SubscriptionId $subNameManagement.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# Management subscription in current tenant selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Store the specified set of tags in a hash table

$tags = @{$tagSpokeName=$tagSpokeValue;$tagCostCenterName=$tagCostCenterValue;$tagCriticalityName=$tagCriticalityValue}

Write-Host ($writeEmptyLine + "# Specified set of tags available to add" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a resource group for Log Analytics if it does not exist. Add specified tags and lock with a CanNotDelete lock

try {
    Get-AzResourceGroup -Name $rgLogAnalyticsWorkspaceName -ErrorAction Stop | Out-Null 
} catch {
    New-AzResourceGroup -Name $rgLogAnalyticsWorkspaceName -Location $region -Force | Out-Null
}

# Set tags Log Analytics resource group
Set-AzResourceGroup -Name $rgLogAnalyticsWorkspaceName -Tag $tags | Out-Null

# Add purpose tag to the Log Analytics resource group
$storeTags = (Get-AzResourceGroup -Name $rgLogAnalyticsWorkspaceName).Tags
$storeTags += @{$tagPurposeName = $tagPurposeValue}
Set-AzResourceGroup -Name $rgLogAnalyticsWorkspaceName -Tag $storeTags | Out-Null

# Lock Log Analytics resource group with a CanNotDelete lock
$lock = Get-AzResourceLock -ResourceGroupName $rgLogAnalyticsWorkspaceName

if ($null -eq $lock){
    New-AzResourceLock -LockName DoNotDeleteLock -LockLevel CanNotDelete -ResourceGroupName $rgLogAnalyticsWorkspaceName -LockNotes "Prevent $rgLogAnalyticsWorkspaceName from deletion" -Force | Out-Null
    }

Write-Host ($writeEmptyLine + "# Resource group $rgLogAnalyticsWorkspaceName available with tags and CanNotDelete lock" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create the Log Analytics workspace if it does not exist and add the specified tags

try {
    Get-AzOperationalInsightsWorkspace -Name $LogAnalyticsWorkspaceName -ResourceGroupName $rgLogAnalyticsWorkspaceName -ErrorAction Stop | Out-Null 
} catch {
    New-AzOperationalInsightsWorkspace -ResourceGroupName $rgLogAnalyticsWorkspaceName -Name $LogAnalyticsWorkspaceName -Location $region -Sku $LogAnalyticsWorkspaceSku -Force | Out-Null
}

# Set tags Log Analytics workspace
Set-AzOperationalInsightsWorkspace -ResourceGroupName $rgLogAnalyticsWorkspaceName -Name $LogAnalyticsWorkspaceName -Tag $tags | Out-Null

# Add purpose tag Log Analytics workspace
$storeTags = (Get-AzOperationalInsightsWorkspace -Name $LogAnalyticsWorkspaceName -ResourceGroupName $rgLogAnalyticsWorkspaceName).Tags
$storeTags += @{$tagPurposeName = $tagPurposeValue}
Set-AzOperationalInsightsWorkspace -ResourceGroupName $rgLogAnalyticsWorkspaceName -Name $LogAnalyticsWorkspaceName -Tag $storeTags | Out-Null

Write-Host ($writeEmptyLine + "# Log Analytics workspace $LogAnalyticsWorkspaceName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Save the Log Analytics workspace in a variable 

$workSpace = Get-AzOperationalInsightsWorkspace -Name $LogAnalyticsWorkspaceName -ResourceGroupName $rgLogAnalyticsWorkspaceName

Write-Host ($writeEmptyLine + "# Log Analytics workspace variable created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## List all solutions and their installation status

# Get-AzOperationalInsightsIntelligencePack -ResourceGroupName $rgLogAnalyticsWorkspaceName -Name $LogAnalyticsWorkspaceName

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Save the list of solutions to enable in a variable 

# Optional solution -> ChangeTracking (also automatically installed by Azure Automation)
# Optional solution -> Updates (also automatically installed by Azure Automation Updating Solution)
# Optional solution -> VMInsights (also automatically installed by linking the Log Analytics workspace with VM Insights)

# Deprecated solution -> KeyVault
# Deprecated solution -> AzureNetworking
# Deprecated solution -> Backup

$lawSolutions = "Security", "SecurityInsights", "AgentHealthAssessment", "AzureActivity", "SecurityCenterFree", "DnsAnalytics", "ADAssessment", "AntiMalware", "ServiceMap", `
"SQLAssessment", "SQLVulnerabilityAssessment", "SQLAdvancedThreatProtection", "AzureAutomation", "Containers", "ChangeTracking", "Updates", "VMInsights"

Write-Host ($writeEmptyLine + "# Solutions variable created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Add the required solutions to the Log Analytics workspace

foreach ($solution in $lawSolutions) {
    New-AzMonitorLogAnalyticsSolution -Type $solution -ResourceGroupName $rgLogAnalyticsWorkspaceName -Location $workSpace.Location -WorkspaceResourceId $workSpace.ResourceId | Out-Null
}

Write-Host ($writeEmptyLine + "# Solutions added to Log Analytics workspace $LogAnalyticsWorkspaceName" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## List all monitor log analytics solutions under the Log Analytics workspace resource group

# Get-AzMonitorLogAnalyticsSolution -ResourceGroupName $rgLogAnalyticsWorkspaceName

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Set the log and metrics settings for the Log Analytics workspace if they don't exist

try {
    Get-AzDiagnosticSetting -Name $LogAnalyticsDiagnosticsName -ResourceId $workSpace.ResourceId -ErrorAction Stop | Out-Null
    
} catch {
    Set-AzDiagnosticSetting -Name $LogAnalyticsDiagnosticsName -ResourceId $workSpace.ResourceId -Category Audit -MetricCategory AllMetrics -Enabled $true `
    -WorkspaceId ($workSpace.ResourceId) | Out-Null
}

Write-Host ($writeEmptyLine + "# Log Analytics workspace $LogAnalyticsWorkspaceName diagnostic settings set" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
