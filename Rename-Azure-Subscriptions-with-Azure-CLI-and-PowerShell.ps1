<#

.SYNOPSIS

A script used to rename Azure Subscriptions with Azure CLI and PowerShell.

.DESCRIPTION

A script used to rename Azure Subscriptions with the use of Azure CLI and Azure PowerShell.

.NOTES

Filename:       Rename-Azure-Subscriptions-with-Azure-CLI-and-PowerShell.ps1
Created:        21/02/2022
Last modified:  21/02/2022
Author:         Wim Matthyssen
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "As IS" with no warranties.

.EXAMPLE

.\Rename-Azure-Subscriptions-with-Azure-CLI-and-PowerShell.ps1

.LINK

https://wmatthyssen.com/2021/04/21/azure-governance-rename-an-azure-subscription-with-azure-cli-and-powershell/
#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Sign in with Azure CLI

az login

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Update Azure CLI to the latest version

az upgrade

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$companyShortName = "<companyShortName>" # <your company short name here> Best is to use a three letter abbreviation. Example: "myh"

$productionShortName = "<production short name here>" # Best is to use a three letter abbreviation. Example: "prd"
$acceptanceShortName = "<acceptance short name here>" # Best is to use a three letter abbreviation. Example: "acc"
$developmentShortName = "<development short name here>" # Best is to use a three letter abbreviation. Example: "dev"
$testShortName = "<test short name here>" # Best is to use a three letter abbreviation. Example: "tst"

$subIdManagement = "<your Managemenet Subcriprition ID here>" # Example: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$subIdIdentity = "<your Identity Subcriprition ID here>" # Example: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$subIdConnectivity = "<your Connectivity Subcriprition ID here>" # Example: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$subIdProduction = "<your Production Subcriprition ID here>" # Example: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$subIdAcceptance = "<your Acceptance Subcriprition ID here>" # Example: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$subIdDevelopment = "<your Development Subcriprition ID here>" # Example: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$subIdTest = "<your Test Subcriprition ID here>" # Example: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$subNameManagement = "sub-management-" + $companyShortName + "-01"
$subNameIdentity = "sub-identity-" + $companyShortName + "-01"
$subNameConnectivity = "sub-connectivity-" + $companyShortName + "-01"
$subNameProduction = "sub-" + $productionShortName + "-" + $companyShortName + "-01"
$subNameAcceptance = "sub-" + $acceptanceShortName + "-" + $companyShortName + "-01"
$subNameDevelopment = "sub-" + $developmentShortName + "-" + $companyShortName + "-01"
$subNameTest = "sub-" + $testShortName + "-" + $companyShortName + "-01"

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Start script execution

Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 6 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Rename subscriptions

az account subscription rename --subscription-id $subIdManagement --name $subNameManagement
az account subscription rename --subscription-id $subIdIdentity --name $subNameIdentity
az account subscription rename --subscription-id $subIdConnectivity --name $subNameConnectivity
az account subscription rename --subscription-id $subIdProduction --name $subNameProduction
az account subscription rename --subscription-id $subIdAcceptance --name $subNameAcceptance
az account subscription rename --subscription-id $subIdDevelopment --name $subNameDevelopment
az account subscription rename --subscription-id $subIdTest --name $subNameTest

Write-Host ($writeEmptyLine + "# All subscriptions are renamed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
