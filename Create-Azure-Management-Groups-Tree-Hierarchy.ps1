<#
.SYNOPSIS

A script used to create an Azure management group tree structure.

.DESCRIPTION

A script used to create an Azure management group tree structure.

Remove the breaking change warning messages.
Create Company management group.
Create Top management groups.
Create Platform management groups.
Create Landing Zones management groups.
Create Confidential Landing Zones management groups.
Move subscriptions from the tenant root group or previous group scope to the appropriate management groups if they are present.

.NOTES

Filename:       Create-Azure-Management-Groups-Tree-Hierarchy.ps1
Created:        31/07/2020
Last modified:  29/11/2023
Author:         Wim Matthyssen
Version:        2.5
PowerShell:     Azure PowerShell and Azure Cloud Shell
Requires:       PowerShell Az (v10.4.1)
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "as is" with no warranties.

.EXAMPLE

.\Create-Azure-Management-Groups-Tree-Hierarchy.ps1

.LINK

https://wmatthyssen.com/2022/04/04/azure-powershell-script-create-a-management-group-tree-hierarchy/
#>

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Functions

function GenerateManagementGroup {
    param (
        [string]$prefix,
        [string]$suffix
    )

    $groupName = "mg-" + $prefix + $suffix
    $groupGuid = New-Guid

    return $groupName, $groupGuid
}

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$companyFullName = "<companyFullName>" # <your company full name here> Example: "wimacorp"
$companyShortName = $companyFullName.Substring(0,3)

# Company management group
$companyManagementGroupName, $companyManagementGroupGuid = GenerateManagementGroup -prefix "" -suffix $companyFullName

# Top management groups
$platformManagementGroupName, $platformManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-platform"
$landingZonesManagementGroupName, $landingZonesManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-landingzones"
$confidentialLandingZonesManagementGroupName, $confidentialLandingZonesManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-confidential-landingzones"
$sandboxesManagementGroupName, $sandboxesManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-sandboxes"
$decommissionedManagementGroupName, $decommissionedManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-decommissioned"

# Platform management groups
$managementManagementGroupName, $managementManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-management"
$connectivityManagementGroupName, $connectivityManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-connectivity"
$identityManagementGroupName, $identityManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-identity"

#Landing zones management groups
$corpManagementGroupName, $corpManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-corp"
$onlineManagementGroupName, $onlineManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-online"
$arcInfraManagementGroupName, $arcInfraManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-arc-infra"
$arcK8sManagementGroupName, $arcK8sManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-arc-k8s"
$arcDataManagementGroupName, $arcDataManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-arc-data"
$avdManagementGroupName, $avdManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-avd"
$aksManagementGroupName, $aksManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-aks"
$sapManagementGroupName, $sapManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-sap"

#Confidential landing zones management groups
$confidentialCorpManagementGroupName, $confidentialCorpManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-confidential-corp"
$confidentialOnlineManagementGroupName, $confidentialOnlineManagementGroupGuid = GenerateManagementGroup -prefix $companyShortName -suffix "-confidential-online"
$confidentialAksManagementGroupName, $confidentialAksManagementGroupGuid  = GenerateManagementGroup -prefix $companyShortName -suffix "-confidential-aks"

# Subscriptions
$subNameManagement = Get-AzSubscription | Where-Object {$_.Name -like "*management*"}
$subNameConnectivity = Get-AzSubscription | Where-Object {$_.Name -like "*connectivity*"}
$subNameIdentity = Get-AzSubscription | Where-Object {$_.Name -like "*identity*"}
$subNameCorpPrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*corp*"}
$subNameCorpDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*corp*"}
$subNameOnlinePrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*online*"}
$subNameOnlineDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*online*"}
$subNameArcInfraPrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*arc*infra*"}
$subNameArcInfraDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*arc*infra*"}
$subNameArcK8sPrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*arc*k8s*"}
$subNameArcK8sDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*arc*k8s*"}
$subNameArcDataPrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*arc*data*"}
$subNameArcDataDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*arc*data*"}
$subNameAvdPrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*avd*"}
$subNameAvdDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*avd*"}
$subNameAksPrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*aks*"}
$subNameAksDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*aks*"}
$subNameSapPrd = Get-AzSubscription | Where-Object {$_.Name -like "*prd*sap*"}
$subNameSapDev = Get-AzSubscription | Where-Object {$_.Name -like "*dev*sap*"}
$subNameTest = Get-AzSubscription | Where-Object {$_.Name -like "*tst*"}
$subNameConfidentialCorpPrd = Get-AzSubscription | Where-Object {$_.Name -like "*confidential*prd*corp*"}
$subNameConfidentialCorpDev = Get-AzSubscription | Where-Object {$_.Name -like "*confidential*dev*corp*"}
$subNameConfidentialOnlinePrd = Get-AzSubscription | Where-Object {$_.Name -like "*confidential*prd*online*"}
$subNameConfidentialOnlineDev = Get-AzSubscription | Where-Object {$_.Name -like "*confidential*dev*online*"}
$subNameConfidentialAksPrd = Get-AzSubscription | Where-Object {$_.Name -like "*confidential*prd*aks*"}
$subNameConfidentialAksDev = Get-AzSubscription | Where-Object {$_.Name -like "*confidential*dev*aks*"}

# Time, colors, and formatting
Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"} | Out-Null 
$foregroundColor1 = "Green"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Remove the breaking change warning messages

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true | Out-Null
Update-AzConfig -DisplayBreakingChangeWarning $false | Out-Null
$warningPreference = "SilentlyContinue"

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script started

Write-Host ($writeEmptyLine + "# Script started. If there are no errors, it may take up to 8 minutes to finish, depending on the volume of resources" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create Company management group
$companyParentGroup = New-AzManagementGroup -GroupName $companyManagementGroupGuid -DisplayName $companyManagementGroupName

Write-Host ($writeEmptyLine + "# Company management group $companyManagementGroupName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create Top management groups

# Create Platform management group
$platformParentGroup = New-AzManagementGroup -GroupName $platformManagementGroupGuid -DisplayName $platformManagementGroupName -ParentObject $companyParentGroup

# Create Landing Zones management group
$landingZonesParentGroup = New-AzManagementGroup -GroupName $landingZonesManagementGroupGuid -DisplayName $landingZonesManagementGroupName -ParentObject $companyParentGroup

# Create Confidential Landing Zones management group
$confidentialLandingZonesParentGroup = New-AzManagementGroup -GroupName $confidentialLandingZonesManagementGroupGuid -DisplayName $confidentialLandingZonesManagementGroupName -ParentObject $companyParentGroup 

# Create Sandbox management group
New-AzManagementGroup -GroupName $sandboxesManagementGroupGuid -DisplayName $sandboxesManagementGroupName -ParentObject $companyParentGroup | Out-Null

# Create Decomission management group
New-AzManagementGroup -GroupName $decommissionedManagementGroupGuid -DisplayName $decommissionedManagementGroupName -ParentObject $companyParentGroup | Out-Null

Write-Host ($writeEmptyLine + "# Top management groups $platformManagementGroupName, $landingZonesManagementGroupName, $confidentialLandingZonesManagementGroupName, $sandboxesManagementGroupName, and `
$decommissionedManagementGroupName created" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create Platform management groups

# Create Management management group
New-AzManagementGroup -GroupName $managementManagementGroupGuid -DisplayName $managementManagementGroupName -ParentObject $platformParentGroup | Out-Null

# Create Connectivity management group
New-AzManagementGroup -GroupName $connectivityManagementGroupGuid -DisplayName $connectivityManagementGroupName -ParentObject $platformParentGroup | Out-Null

# Create Identity management group
New-AzManagementGroup -GroupName $identityManagementGroupGuid -DisplayName $identityManagementGroupName -ParentObject $platformParentGroup | Out-Null

Write-Host ($writeEmptyLine + "# Platform management groups $managementManagementGroupName, $connectivityManagementGroupName and $identityManagementGroupName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create Landing Zones management groups

# Create Corp management group
New-AzManagementGroup -GroupName $corpManagementGroupGuid -DisplayName $corpManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

# Create Online management group
New-AzManagementGroup -GroupName $onlineManagementGroupGuid -DisplayName $onlineManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

# Create Arc infra management group
New-AzManagementGroup -GroupName $arcInfraManagementGroupGuid -DisplayName $arcInfraManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

# Create Arc k8s management group
New-AzManagementGroup -GroupName $arcK8sManagementGroupGuid -DisplayName $arcK8sManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

# Create Arc data management group
New-AzManagementGroup -GroupName $arcDataManagementGroupGuid -DisplayName $arcDataManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

# Create Avd management group
New-AzManagementGroup -GroupName $avdManagementGroupGuid -DisplayName $avdManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

# Create Aks management group
New-AzManagementGroup -GroupName $aksManagementGroupGuid -DisplayName $aksManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

# Create Sap management group
New-AzManagementGroup -GroupName $sapManagementGroupGuid -DisplayName $sapManagementGroupName -ParentObject $landingZonesParentGroup | Out-Null

Write-Host ($writeEmptyLine + "# Landing Zones management groups created" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create Confidential Landing Zones management groups

# Create Confidential Corp management group
New-AzManagementGroup -GroupName $confidentialCorpManagementGroupGuid -DisplayName $confidentialCorpManagementGroupName -ParentObject $confidentialLandingZonesParentGroup | Out-Null

# Create Confidentials Online management group
New-AzManagementGroup -GroupName $confidentialOnlineManagementGroupGuid -DisplayName $confidentialOnlineManagementGroupName -ParentObject $confidentialLandingZonesParentGroup | Out-Null

# Create Confidentials Aks management group
New-AzManagementGroup -GroupName $confidentialAksManagementGroupGuid -DisplayName $confidentialAksManagementGroupName -ParentObject $confidentialLandingZonesParentGroup | Out-Null

Write-Host ($writeEmptyLine + "# Confidential Landing Zones management groups created" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Move subscriptions from the tenant root group or previous group scope to the appropriate management groups if they are present

# Move Management subscription, if it exists
If($subNameManagement)
{
    New-AzManagementGroupSubscription -GroupId $managementManagementGroupGuid -SubscriptionId $subNameManagement.SubscriptionId | Out-Null
}

# Move Connectivity subscription, if it exists
If($subNameConnectivity)
{
    New-AzManagementGroupSubscription -GroupId $connectivityManagementGroupGuid -SubscriptionId $subNameConnectivity.SubscriptionId | Out-Null
}

# Move Identity subscription, if it exists
If($subNameIdentity)
{
    New-AzManagementGroupSubscription -GroupId $identityManagementGroupGuid -SubscriptionId $subNameIdentity.SubscriptionId | Out-Null
}

# Move Corp Production subscription, if it exists
If($subNameCorpPrd)
{
    New-AzManagementGroupSubscription -GroupId $corpManagementGroupGuid  -SubscriptionId $subNameCorpPrd.SubscriptionId | Out-Null
}

# Move Corp Development subscription, if it exists
If($subNameCorpDev)
{
    New-AzManagementGroupSubscription -GroupId $corpManagementGroupGuid  -SubscriptionId $subNameCorpDev.SubscriptionId | Out-Null
}

# Move Online Production subscription, if it exists
If($subNameOnlinePrd)
{
    New-AzManagementGroupSubscription -GroupId $onlineManagementGroupGuid -SubscriptionId $subNameOnlinePrd.SubscriptionId | Out-Null
}

# Move Online Development subscription, if it exists
If($subNameOnlineDev )
{
    New-AzManagementGroupSubscription -GroupId $onlineManagementGroupGuid -SubscriptionId $subNameOnlineDev.SubscriptionId | Out-Null
}

# Move Arc Infra Production subscription, if it exists
If($subNameArcInfraPrd)
{
    New-AzManagementGroupSubscription -GroupID $arcInfraManagementGroupGuid -SubscriptionId $subNameArcInfraPrd.SubscriptionId | Out-Null
}

# Move Arc Infra Development subscription, if it exists
If($subNameArcInfraDev)
{
    New-AzManagementGroupSubscription -GroupID $arcInfraManagementGroupGuid -SubscriptionId $subNameArcInfraDev.SubscriptionId | Out-Null
}

# Move Arc K8s Production subscription, if it exists
If($subNameArcK8sPrd)
{
    New-AzManagementGroupSubscription -GroupID $arcK8sManagementGroupGuid -SubscriptionId $subNameArcK8sPrd.SubscriptionId | Out-Null
}

# Move Arc K8s Development subscription, if it exists
If($subNameArcK8sDev)
{
    New-AzManagementGroupSubscription -GroupID $arcK8sManagementGroupGuid -SubscriptionId $subNameArcK8sDev.SubscriptionId | Out-Null
}

# Move Arc Data Production subscription, if it exists
If($subNameArcDataPrd)
{
    New-AzManagementGroupSubscription -GroupID $arcDataManagementGroupGuid -SubscriptionId $subNameArcDataPrd.SubscriptionId | Out-Null
}

# Move Arc Data Development subscription, if it exists
If($subNameArcDataDev)
{
    New-AzManagementGroupSubscription -GroupID $arcDataManagementGroupGuid -SubscriptionId $subNameArcDataDev.SubscriptionId | Out-Null
}

# Move AVD Production subscription, if it exists
If($subNameAvdPrd)
{
    New-AzManagementGroupSubscription -GroupID $avdManagementGroupGuid -SubscriptionId $subNameAvdPrd.SubscriptionId | Out-Null
}

# Move AVD Development subscription, if it exists
If($subNameAvdDev)
{
    New-AzManagementGroupSubscription -GroupID $avdManagementGroupGuid -SubscriptionId $subNameAvdDev.SubscriptionId | Out-Null
}

# Move AKS Production subscription, if it exists
If($subNameAksPrd)
{
    New-AzManagementGroupSubscription -GroupID $aksManagementGroupGuid -SubscriptionId $subNameAksPrd.SubscriptionId | Out-Null
}

# Move AKS Development subscription, if it exists
If($subNameAksDev)
{
    New-AzManagementGroupSubscription -GroupID $aksManagementGroupGuid -SubscriptionId $subNameAksDev.SubscriptionId | Out-Null
}

# Move SAP Production subscription, if it exists
If($subNameSapPrd)
{
    New-AzManagementGroupSubscription -GroupID $sapManagementGroupGuid -SubscriptionId $subNameSapPrd.SubscriptionId | Out-Null
}

# Move SAP Development subscription, if it exists
If($subNameSapDev)
{
    New-AzManagementGroupSubscription -GroupID $sapManagementGroupGuid -SubscriptionId $subNameSapDev.SubscriptionId | Out-Null
}

# Move Test subscription, if it exists
If($subNameTest)
{
    New-AzManagementGroupSubscription -GroupId $sandboxesManagementGroupGuid  -SubscriptionId $subNameTest.SubscriptionId | Out-Null
}

# Move Confidential Corp Production subscription, if it exists
If($subNameConfidentialCorpPrd)
{
    New-AzManagementGroupSubscription -GroupId $confidentialCorpManagementGroupGuid  -SubscriptionId $subNameConfidentialCorpPrd.SubscriptionId | Out-Null
}

# Move Confidential Corp Development subscription, if it exists
If($subNameConfidentialCorpDev)
{
    New-AzManagementGroupSubscription -GroupId $confidentialCorpManagementGroupGuid  -SubscriptionId $subNameConfidentialCorpDev.SubscriptionId | Out-Null
}

# Move Confidential Online Production subscription, if it exists
If($subNameConfidentialOnlinePrd)
{
    New-AzManagementGroupSubscription -GroupId $confidentialOnlineManagementGroupGuid -SubscriptionId $subNameConfidentialOnlinePrd.SubscriptionId | Out-Null
}

# Move Confidential Online Development subscription, if it exists
If($subNameConfidentialOnlineDev )
{
    New-AzManagementGroupSubscription -GroupId $confidentialOnlineManagementGroupGuid -SubscriptionId $subNameConfidentialOnlineDev.SubscriptionId | Out-Null
}

# Move Confidential AKS Production subscription, if it exists
If($subNameConfidentialAksPrd)
{
    New-AzManagementGroupSubscription -GroupID $confidentialAksManagementGroupGuid -SubscriptionId $subNameConfidentialAksPrd.SubscriptionId | Out-Null
}

# Move Confidential AKS Development subscription, if it exists
If($subNameConfidentialAksDev)
{
    New-AzManagementGroupSubscription -GroupID $confidentialAksManagementGroupGuid -SubscriptionId $subNameConfidentialAksDev.SubscriptionId | Out-Null
}

Write-Host ($writeEmptyLine + "# Subscriptions moved to management groups" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
