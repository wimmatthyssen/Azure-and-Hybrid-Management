<#
.SYNOPSIS

A script used to create a management groups tree structure

.DESCRIPTION

A script used to create a management groups tree structure. 
When all management groups are created the Azure subscriptions will be moved to the corresponding management group.

.NOTES

Filename:       Create-Azure-Management-Groups-Tree-Hierarchy.ps1
Created:        31/07/2020
Last modified:  21/04/2022
Author:         Wim Matthyssen
PowerShell:     Azure PowerShell or Azure Cloud Shell
Version:        Install latest Azure PowerShell modules
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "As Is" with no warranties.


.EXAMPLE

.\Create-Azure-Management-Groups-Tree-Hierarchy.ps1

.LINK

https://wmatthyssen.com/2020/08/01/azure-powershell-script-create-a-management-group-tree-hierarchy/
#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$companyFullName = "<companyFullName>" # <your company full name here> Example: "myhcjourney"
$companyShortName ="<companyShortName>" # <your company short name here> Best is to use a three letter abbreviation. Example: "myh"

$companyManagementGroupName = "mg-" + $companyFullName 
$companyManagementGroupGuid = New-Guid

$platformManagementGroupName = "mg-" + $companyShortName + "-platform"
$platformManagementGroupGuid = New-Guid
$landingZonesManagementGroupName = "mg-" + $companyShortName + "-landingzones"
$landingZonesManagementGroupGuid = New-Guid
$sandboxesManagementGroupName = "mg-" + $companyShortName + "-sandboxes"
$sandboxesManagementGroupGuid = New-Guid
$decommissionedManagementGroupName = "mg-" + $companyShortName + "-decommissioned"
$decommissionedManagementGroupGuid = New-Guid

$managementManagementGroupName = "mg-" + $companyShortName + "-management"
$managementManagementGroupGuid = New-Guid
$connectivityManagementGroupName = "mg-" + $companyShortName + "-connectivity"
$connectivityManagementGroupGuid = New-Guid
$identityManagementGroupName = "mg-" + $companyShortName + "-identity"
$identityManagementGroupGuid = New-Guid

$corpManagementGroupName = "mg-" + $companyShortName + "-corp"
$corpManagementGroupGuid = New-Guid
$onlineManagementGroupName = "mg-" + $companyShortName + "-online"
$onlineManagementGroupGuid = New-Guid
$sapManagementGroupName = "mg-" + $companyShortName + "-sap"
$sapManagementGroupGuid = New-Guid

$subNameManagement = Get-AzSubscription | Where-Object {$_.Name -like "*management*"}
$subNameConnectivity = Get-AzSubscription | Where-Object {$_.Name -like "*connectivity*"}
$subNameIdentity = Get-AzSubscription | Where-Object {$_.Name -like "*identity*"}
$subNameCorpPrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*corp*"}
$subNameCorpDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*corp*"}
$subNameOnlinePrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*online*"}
$subNameOnlineDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*online*"}
$subNameSapPrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*sap*"}
$subNameSapDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*sap*"}
$subNameTest = Get-AzSubscription | Where-Object {$_.Name -like "*tst*"}

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
    Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 5 minute to complete" + $writeSeperatorSpaces + $currentTime)`
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
        Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 5 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine 
        }
}

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Suppress breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create Company management group

New-AzManagementGroup -GroupName $companyManagementGroupGuid -DisplayName $companyManagementGroupName | Out-Null

# Store Company management group in a variable
$companyParentGroup = Get-AzManagementGroup -GroupName $companyManagementGroupGuid

Write-Host ($writeEmptyLine + "# Company management group $companyManagementGroupName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create Top management groups

# Create Platform management group
New-AzManagementGroup -GroupName $platformManagementGroupGuid -DisplayName $platformManagementGroupName -ParentObject $companyParentGroup | Out-Null

# Create Landing Zones management group
New-AzManagementGroup -GroupName $landingZonesManagementGroupGuid -DisplayName $landingZonesManagementGroupName -ParentObject $companyParentGroup | Out-Null

# Create Sandbox management group
New-AzManagementGroup -GroupName $sandboxesManagementGroupGuid -DisplayName $sandboxesManagementGroupName -ParentObject $companyParentGroup | Out-Null

# Create Decomission management group
New-AzManagementGroup -GroupName $decommissionedManagementGroupGuid -DisplayName $decommissionedManagementGroupName -ParentObject $companyParentGroup | Out-Null

# Store specific Top management groups in variables
$platformParentGroup = Get-AzManagementGroup -GroupName $platformManagementGroupGuid 
$landingZonesParentGroup = Get-AzManagementGroup -GroupName $landingZonesManagementGroupGuid

Write-Host ($writeEmptyLine + "# Top management groups $platformManagementGroupName, $landingZonesManagementGroupName, $sandboxesManagementGroupName, and `
$decommissionedManagementGroupName created" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create Platform management groups

# Create Management management group
New-AzManagementGroup -GroupName $managementManagementGroupGuid -DisplayName $managementManagementGroupName -ParentObject $platformParentGroup | Out-Null

# Create Connectivity management group
New-AzManagementGroup -GroupName $connectivityManagementGroupGuid -DisplayName $connectivityManagementGroupName -ParentObject $platformParentGroup | Out-Null

# Create Identity management group
New-AzManagementGroup -GroupName $identityManagementGroupGuid -DisplayName $identityManagementGroupName -ParentObject $platformParentGroup | Out-Null

Write-Host ($writeEmptyLine + "# Platform management groups $managementManagementGroupName, $connectivityManagementGroupName and `
$identityManagementGroupName created" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create Landing Zones management groups

# Create Corp management group
New-AzManagementGroup -GroupName $corpManagementGroupGuid -DisplayName $corpManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

# Create Online management group
New-AzManagementGroup -GroupName $onlineManagementGroupGuid -DisplayName $onlineManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

# Create SAP management group
New-AzManagementGroup -GroupName $sapManagementGroupGuid -DisplayName $sapManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

Write-Host ($writeEmptyLine + "# Landing Zones management groups $corpManagementGroupName, $onlineManagementGroupName and `
$sapManagementGroupName created" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Move subscriptions under the tenant root group to the correct management groups, if they exist

# Move Management subscription, if it exists
If(!! $subNameManagement)
{
    New-AzManagementGroupSubscription -GroupId $managementManagementGroupGuid -SubscriptionId $subNameManagement.SubscriptionId
}

# Move Connectivity subscription, if it exists
If(!! $subNameConnectivity)
{
    New-AzManagementGroupSubscription -GroupId $connectivityManagementGroupGuid -SubscriptionId $subNameConnectivity.SubscriptionId
}

# Move Identity subscription, if it exists
If(!! $subNameIdentity)
{
    New-AzManagementGroupSubscription -GroupId $identityManagementGroupGuid -SubscriptionId $subNameIdentity.SubscriptionId
}

# Move Corp Production subscription, if it exists
If(!! $subNameCorpPrd)
{
    New-AzManagementGroupSubscription -GroupId $corpManagementGroupGuid  -SubscriptionId $subNameCorpPrd.SubscriptionId
}

# Move Corp Development subscription, if it exists
If(!! $subNameCorpDev)
{
    New-AzManagementGroupSubscription -GroupId $corpManagementGroupGuid  -SubscriptionId $subNameCorpDev.SubscriptionId
}

# Move Online Production subscription, if it exists
If(!! $subNameOnlinePrd)
{
    New-AzManagementGroupSubscription -GroupId $onlineManagementGroupGuid -SubscriptionId $subNameOnlinePrd.SubscriptionId
}

# Move Online Development subscription, if it exists
If(!! $subNameOnlineDev )
{
    New-AzManagementGroupSubscription -GroupId $onlineManagementGroupGuid -SubscriptionId $subNameOnlineDev.SubscriptionId
}

# Move SAP Production subscription, if it exists
If(!! $subNameSapPrd)
{
    New-AzManagementGroupSubscription -GroupID $sapManagementGroupGuid -SubscriptionId $subNameSapPrd.SubscriptionId
}

# Move SAP Development subscription, if it exists
If(!! $subNameSapDev)
{
    New-AzManagementGroupSubscription -GroupID $sapManagementGroupGuid -SubscriptionId $subNameSapDev.SubscriptionId
}

# Move Test subscription, if it exists
If(!! $subNameTest)
{
    New-AzManagementGroupSubscription -GroupId $sandboxesManagementGroupGuid  -SubscriptionId $subNameTest.SubscriptionId
}

Write-Host ($writeEmptyLine + "# Subscriptions moved to management groups" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------