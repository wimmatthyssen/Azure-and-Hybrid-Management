<#
.SYNOPSIS

A script used to create a Log Analytics workspace with enabled solutions in the Management subscription.

.DESCRIPTION

A script used to create a Log Analytics workspace with enabled solutions in the Management subscription.
The script will do all of the following:

Check if the PowerShell window is running as Administrator (when not running from Cloud Shell), otherwise the Azure PowerShell script will be exited.
Suppress breaking change warning messages.
Change the current context to use a management subscription (a subscription with *management* in the Subscription name will be automatically selected).
Store a specified set of tags in a hash table.
Create a management resource group for the Log Analytics resources if it not already exists. Also apply the necessary tags to this resource group and lock it with a CanNotDelete lock.
Create the Log Analytics workspace if it does not exist and add specified tags.
Get the Log Analytics workspace ID and store in a variable for later use.
Store the list of solutions to enable in a variable for later use.
Add the required solutions to the Log Analytics workspace.
Set the log and metrics settings for the Log Analytics workspace, if they don't exist.

.NOTES

Filename:       Create-Log-Analytics-workspace-management-subscription.ps1
Created:        14/10/2021
Last modified:  01/08/2022
Author:         Wim Matthyssen
Version:        2.0
PowerShell:     PowerShell 5.1 and Azure PowerShell
Requires:       PowerShell Az (v5.9.0)
Action:         Change variables were needed to fit your needs.
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE

Connect-AzAccount
.\Create-Log-Analytics-workspace-management-subscription.ps1

.LINK

https://wmatthyssen.com/2022/08/01/azure-powershell-script-create-a-log-analytics-workspace-in-your-management-subscription/
#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$spoke = "hub"
$abbraviationManagement = "management"
$region = #<your region here> The used Azure public region. Example: "westeurope"

$rgManagementHub = #<your Management rg here> The Azure resource group in which the new Log Analytics resources will be created. Example: "rg-hub-myh-management-01"
$lawWorkSpaceName = #<your Log Analytics workspace name here> The name for your Log Analytics workspace. Example: "law-hub-myh-01"
$lawSku = "pergb2018"
$lawDiagnosticsName = #<your Log Analytics Diagnostics settings name here> The name of the new diagnostic settings for your Log Analytics workspace. Example: "diag-law-hub-myh-01"

$tagSpokeName = #<your environment tag name here> The environment tag name you want to use. Example:"Env"
$tagSpokeValue = "$($spoke[0].ToString().ToUpper())$($spoke.SubString(1))"
$tagCostCenterName  = #<your costCenter tag name here> The costCenter tag name you want to use. Example:"CostCenter"
$tagCostCenterValue = #<your costCenter tag value here> The costCenter tag value you want to use. Example: "23"
$tagCriticalityName = #<your businessCriticality tag name here> The businessCriticality tag name you want to use. Example:"Criticality"
$tagCriticalityValue = #<your businessCriticality tag value here> The businessCriticality tag value you want to use. Example: "High"
$tagPurposeName  = #<your purpose tag name here> The purpose tag name you want to use. Example:"Purpose"
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

## Change the current context to use the Management subscription

$subNameManagement = Get-AzSubscription | Where-Object {$_.Name -like "*management*"}
$tenant = Get-AzTenant | Where-Object {$_.Name -like "*$companyShortName*"}

Set-AzContext -TenantId $tenant.TenantId -SubscriptionId $subNameManagement.SubscriptionId | Out-Null 

Write-Host ($writeEmptyLine + "# Management Subscription in current tenant selected" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Store the specified set of tags in a hash table

$tags = @{$tagSpokeName=$tagSpokeValue;$tagCostCenterName=$tagCostCenterValue;$tagCriticalityName=$tagCriticalityValue}

Write-Host ($writeEmptyLine + "# Specified set of tags available to add" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a management resource group if it not exists. Add specified tags and lock with a CanNotDelete lock

try {
    Get-AzResourceGroup -Name $rgManagementHub -ErrorAction Stop | Out-Null 
} catch {
    New-AzResourceGroup -Name $rgManagementHub -Location $region -Force | Out-Null
}

# Set tags rg management
Set-AzResourceGroup -Name $rgManagementHub -Tag $tags | Out-Null

# Add purpose tag rg management
$storeTags = (Get-AzResourceGroup -Name $rgManagementHub).Tags
$storeTags += @{$tagPurposeName = $tagPurposeValue}
Set-AzResourceGroup -Name $rgManagementHub -Tag $storeTags | Out-Null

# Lock rg management with a CanNotDelete lock
$lock = Get-AzResourceLock -ResourceGroupName $rgManagementHub

if ($null -eq $lock){
    New-AzResourceLock -LockName DoNotDeleteLock -LockLevel CanNotDelete -ResourceGroupName $rgManagementHub -LockNotes "Prevent $rgManagementHub from deletion" -Force | Out-Null
    }

Write-Host ($writeEmptyLine + "# Resource group $rgManagementHub available with tags and CanNotDelete lock" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create the Log Analytics workspace if it does not exist and add specified tags

try {
    Get-AzOperationalInsightsWorkspace -Name $lawWorkSpaceName -ResourceGroupName $rgManagementHub -ErrorAction Stop | Out-Null 
} catch {
    New-AzOperationalInsightsWorkspace -ResourceGroupName $rgManagementHub -Name $lawWorkSpaceName -Location $region -Sku $lawSku -Force | Out-Null
}

# Set tags Log Analytics workspace
Set-AzOperationalInsightsWorkspace -ResourceGroupName $rgManagementHub -Name $lawWorkSpaceName -Tag $tags | Out-Null

# Add purpose tag Log Analytics workspace
$storeTags = (Get-AzOperationalInsightsWorkspace -Name $lawWorkSpaceName -ResourceGroupName $rgManagementHub).Tags
$storeTags += @{$tagPurposeName = $tagPurposeValue}
Set-AzOperationalInsightsWorkspace -ResourceGroupName $rgManagementHub -Name $lawWorkSpaceName -Tag $storeTags | Out-Null

Write-Host ($writeEmptyLine + "# Log Analytics workspace $lawWorkSpaceName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Get the Log Analytics workspace ID and store in a variable for later use

$workSpace = Get-AzOperationalInsightsWorkspace -Name $lawWorkSpaceName -ResourceGroupName $rgManagementHub

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

##  List all solutions and their installation status

# Get-AzOperationalInsightsIntelligencePack -ResourceGroupName $rgManagementHub -Name $lawWorkSpaceName

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Store the list of solutions to enable in a variable for later use

# Optional solution -> ChangeTracking (also automatically installed by Azure Automation)
# Optional solution -> Updates (also automatically installed by Azure Automation Updating Solution)
# Optional solution -> VMInsights (also automatically installed by linking the Log Analytics workspace with VM Insights)

# Deprecated solution -> KeyVault
# Deprecated solution -> AzureNetworking

$lawSolutions = "Security", "SecurityInsights", "AgentHealthAssessment", "AzureActivity", "SecurityCenterFree", "Backup", "DnsAnalytics", "ADAssessment", "AntiMalware", "ServiceMap", `
"SQLAssessment", "SQLVulnerabilityAssessment", "SQLAdvancedThreatProtection", "AzureAutomation", "Container", "ChangeTracking", "Updates", "VMInsights"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Add the required solutions to the Log Analytics workspace

foreach ($solution in $lawSolutions) {
    New-AzMonitorLogAnalyticsSolution -Type $solution -ResourceGroupName $rgManagementHub -Location $workSpace.Location -WorkspaceResourceId $workSpace.ResourceId | Out-Null
}

Write-Host ($writeEmptyLine + "# Solutions added to $lawWorkSpaceName" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## List all monitor log analytics solutions under the Log Analytics workspace resource group

# Get-AzMonitorLogAnalyticsSolution -ResourceGroupName $rgManagementHub

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Set the log and metrics settings for the Log Analytics workspace, if they don't exist

try {
    Get-AzDiagnosticSetting -Name $lawDiagnosticsName -ResourceId $workSpace.ResourceId -ErrorAction Stop | Out-Null
    
} catch {
    Set-AzDiagnosticSetting -Name $lawDiagnosticsName -ResourceId $workSpace.ResourceId -Category Audit -MetricCategory AllMetrics -Enabled $true `
    -WorkspaceId ($workSpace.ResourceId) | Out-Null
}

Write-Host ($writeEmptyLine + "# Diagnostic settings set" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
