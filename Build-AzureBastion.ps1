<#
.SYNOPSIS

A script used to setup and configure Azure Bastion within the HUB spoke VNet.

.DESCRIPTION

A script used to setup and configure Azure Bastion (basic SKU) within the HUB spoke VNet. 
The script will create a resource group for the Azure Bastion resources (if it not already exists).
Then it will create the AzureBastionSubnet (/26) with an associated network security group (NSG), which holds all the required inbound and outbound security rules (if it not already exists). 
If the AzureBastionSubnet exists but does not have an associated NSG, it will attach the new created NSG. 
The script will also create a Public IP Address (PIP) for the Bastion host (if it not exists), and create the Bastion host (basic SKU), which can take up to 6 minutes (if it not exists). 
It will also set the log and metrics settings for the bastion resource if they don't exist. 
And at the end it will lock the Azure Bastion resource group with a CanNotDelete lock.

.NOTES

Filename:       Build-AzureBastion.ps1
Created:        01/06/2021
Last modified:  07/01/2022
Author:         Wim Matthyssen
PowerShell:     Azure Cloud Shell or Azure PowerShell
Version:        Install latest Azure Powershell modules (at least Az version 5.9.0 and Az.Network version 4.7.0 is required)
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "As IS" with no warranties.

.EXAMPLE

.\Build-AzureBastion.ps1

.LINK

https://wmatthyssen.com/2021/06/02/azure-bastion-azure-powershell-deployment-script/
#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$spoke = "hub"
$location = #<your region here> The used Azure public region. Example: "westeurope"
$purpose = "bastion"

$rgBastion = #<your Bastion rg here> The new Azure resource group in which the new Bastion resource will be created. Example: "rg-hub-myh-bastion"
$rgNetworkSpoke = #<your VNet rg here> The Azure resource group in which your existing VNet is deployed. Example: "rg-hub-myh-networking"
$rgLogAnalyticsSpoke = #<your Log Analytics rg here> The Azure resource group your existing Log Analytics workspace is deployed. Example: "rg-hub-myh-management"

$vnetName = #<your VNet name here> The existing VNet in which the Bastion resource will be created. Example: "vnet-hub-myh-weu"
$subnetNameBastion = "AzureBastionSubnet"
$subnetBastionAddress = #<your AzureBastionSubnet range here> The subnet must have a minimum subnet size of /26. Example: "10.1.1.128/26"
$nsgNameBastion = #<your AzureBastionSubnet NSG name here> The name of the NSG associated with the AzureBastionSubnet. Example: "nsg-AzureBastionSubnet"

$bastionName = #<your name here> The name of the new Bastion resource. Example: "bas-hub-myh"
$bastionPipName = #<your Bastion PIP here> The public IP address of the Bastion resource. Example: "pip-bas-hub-myh"
$bastionPipAllocationMethod = "Static"
$bastionPipSku = "Standard"

$logAnalyticsName = #<your Log Analytics workspace name here> The name of your existing Log Analytics workspace. Example: "law-hub-myh-01"
$bastionDiagnosticsName = #<your Bastion Diagnostics settings name here> The name of the new diagnostic settings for Bastion. Example: "diag-bas-hub-myh"

$tagCostCenter = "it"
$tagBusinessCriticality = "critical"

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Prerequisites

## Check if running as Administrator (when not running from Cloud Shell), otherwise close the PowerShell window

if ($PSVersionTable.Platform -eq "Unix") {
    Write-Host ($writeEmptyLine + "# Running in Cloud Shell" + $writeSeperatorSpaces + $currentTime)
} else {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdministrator -eq $false) {
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime +$writeEmptyLine)`
    -foregroundcolor $foregroundColor1
        Start-Sleep -s 4
    exit} else {
        ## Import Az module into the PowerShell session
        Import-Module Az
        Write-Host ($writeEmptyLine + "# Az module imported" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine
    }
}

## Suppress breaking change warning messages

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Start script execution

Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 7 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a resource group for the Azure Bastion resources if it not exists

try {
    Get-AzResourceGroup -Name $rgBastion -ErrorAction Stop
} catch {
    New-AzResourceGroup -Name $rgBastion -Location $location `
    -Tag @{env=$spoke;costCenter=$tagCostCenter;businessCriticality=$tagBusinessCriticality;purpose=$purpose;vnet=$vnetName} -Force
}

Write-Host ($writeEmptyLine + "# Resource group $rgBastion available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create the AzureBastionSubnet with the network security group (with the required inbound and outbound security rules) if it not exists

## Inbound rules

$inboundRule1 = New-AzNetworkSecurityRuleConfig -Name "Allow_TCP_443_Internet" -Description "Allow_TCP_443_Internet" `
-Access Allow -Protocol TCP -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

$inboundRule2 = New-AzNetworkSecurityRuleConfig -Name "Allow_TCP_443_GatewayManager" -Description "Allow_TCP_443_GatewayManager" `
-Access Allow -Protocol TCP -Direction Inbound -Priority 110 -SourceAddressPrefix GatewayManager -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

$inboundRule3 = New-AzNetworkSecurityRuleConfig -Name "Allow_TCP_4443_GatewayManager" -Description "Allow_TCP_4443_GatewayManager" `
-Access Allow -Protocol TCP -Direction Inbound -Priority 120 -SourceAddressPrefix GatewayManager -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 4443

$inboundRule4 = New-AzNetworkSecurityRuleConfig -Name "Allow_TCP_443_AzureLoadBalancer" -Description "Allow_TCP_443_AzureLoadBalancer" `
-Access Allow -Protocol TCP -Direction Inbound -Priority 130 -SourceAddressPrefix AzureLoadBalancer -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

## The rule below denies all other inbound virtual network access

$inboundRule5 = New-AzNetworkSecurityRuleConfig -Name "Deny_any_other_traffic" -Description "Deny_any_other_traffic" `
-Access Deny -Protocol * -Direction Inbound -Priority 900 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *

## Outbound rules

$outboundRule1 = New-AzNetworkSecurityRuleConfig -Name "Allow_TCP_3389_VirtualNetwork" -Description "Allow_TCP_3389_VirtualNetwork" `
-Access Allow -Protocol TCP -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 3389

$outboundRule2 = New-AzNetworkSecurityRuleConfig -Name "Allow_TCP_22_VirtualNetwork" -Description "Allow_TCP_22_VirtualNetwork" `
-Access Allow -Protocol TCP -Direction Outbound -Priority 110 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 22

$outboundRule3 = New-AzNetworkSecurityRuleConfig -Name "Allow_TCP_443_AzureCloud" -Description "Allow_TCP_443_AzureCloud" `
-Access Allow -Protocol TCP -Direction Outbound -Priority 120 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix AzureCloud -DestinationPortRange 443

## Create the NSG if it not exists

try {
    Get-AzNetworkSecurityGroup -Name $nsgNameBastion -ResourceGroupName $rgNetworkSpoke -ErrorAction Stop
} catch {
    New-AzNetworkSecurityGroup -Name $nsgNameBastion -ResourceGroupName $rgNetworkSpoke -Location $location `
    -SecurityRules $inboundRule1,$inboundRule2,$inboundRule3,$inboundRule4,$inboundRule5,$outboundRule1,$outboundRule2,$outboundRule3 `
    -Tag @{env=$spoke;costCenter=$tagCostCenter;businessCriticality=$tagBusinessCriticality;purpose=$purpose} -Force
}

Write-Host ($writeEmptyLine + "# NSG $nsgNameBastion available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## Create the AzureBastionSubnet if it not exists

try {
    $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupname $rgNetworkSpoke

    $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetNameBastion -VirtualNetwork $vnet -ErrorAction Stop
} catch {
    $subnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetNameBastion -VirtualNetwork $vnet -AddressPrefix $subnetBastionAddress

    $vnet | Set-AzVirtualNetwork
}

## Attach the NSG to the AzureBastionSubnet (also if the AzureBastionSubnet exsists and misses and NSG)

$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetNameBastion -VirtualNetwork $vnet
$nsg = Get-AzNetworkSecurityGroup -Name $nsgNameBastion -ResourceGroupName $rgNetworkSpoke
$subnet.NetworkSecurityGroup = $nsg
$vnet | Set-AzVirtualNetwork

Write-Host ($writeEmptyLine + "# Subnet $subnetNameBastion available with attached NSG $nsgNameBastion" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create a Public IP Address (PIP) for the Bastion host if it not exists

try {
    $bastionPip = Get-AzPublicIpAddress -Name $bastionPipName -ResourceGroupName $rgBastion -ErrorAction Stop
} catch {
    $bastionPip = New-AzPublicIpAddress -Name $bastionPipName -ResourceGroupName $rgBastion -Location $location -AllocationMethod $bastionPipAllocationMethod -Sku $bastionPipSku `
    -Tag @{env=$spoke;costCenter=$tagCostCenter;businessCriticality=$tagBusinessCriticality;purpose=$purpose;vnet=$vnetName} -Force
}

Write-Host ($writeEmptyLine + "# Pip " + $bastionPipName + " available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create the Bastion host (it takes around 6 minutes for the Bastion host to be deployed) if it not exists

try {
    $bastion = Get-AzBastion -Name $bastionName -ResourceGroupName $rgBastion -ErrorAction Stop
} catch {
    Write-Host ($writeEmptyLine + "# Bastion host deployment started, this can take up to 6 minutes" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor2 $writeEmptyLine

    $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupname $rgNetworkSpoke

    $bastion = New-AzBastion -ResourceGroupName $rgBastion -Name $bastionName -PublicIpAddress $bastionPip -VirtualNetwork $vnet `
    -Tag @{env=$spoke;costCenter=$tagCostCenter;businessCriticality=$tagBusinessCriticality;purpose=$purpose;vnet=$vnetName}
}

Write-Host ($writeEmptyLine + "# Bastion host $bastionName available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Set the log and metrics settings for the bastion resource if they don't exist

try {
    Get-AzDiagnosticSetting -Name $bastionDiagnosticsName -ResourceId ($bastion.Id) -ErrorAction Stop
} catch {
    $workSpace = Get-AzOperationalInsightsWorkspace -Name $logAnalyticsName -ResourceGroupName $rgLogAnalyticsSpoke
    
    Set-AzDiagnosticSetting -Name $bastionDiagnosticsName -ResourceId ($bastion.Id) -Category BastionAuditLogs -MetricCategory AllMetrics -Enabled $true `
    -WorkspaceId ($workSpace.ResourceId)
}

Write-Host ($writeEmptyLine + "# Diagnostic settings set" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Lock the Azure Bastion resource group with a CanNotDelete lock

$lock = Get-AzResourceLock -ResourceGroupName $rgBastion

if ($null -eq $lock){
    New-AzResourceLock -LockName DoNotDeleteLock -LockLevel CanNotDelete -ResourceGroupName $rgBastion -LockNotes "Prevent $rgBastion from deletion" -Force
    }

Write-Host ($writeEmptyLine + "# Resource group $rgBastion locked" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
