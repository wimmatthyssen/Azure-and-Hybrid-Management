<#
.SYNOPSIS
A script used to create an Azure management group for decommissioning Azure subscriptions, placed under the company management group hierarchy.

.DESCRIPTION
A script used to create an Azure management group for decommissioning Azure subscriptions, placed under the company management group hierarchy.
Suppress Azure PowerShell breaking change warning messages to avoid unnecessary output.
Write script started.
Permission checks.
Get parent Management group.
Create the decommissioned Management Group if it does not exist.
Write script completed.

.NOTES
Filename:       Create-Decommissioned-Management-group.ps1
Created:        11/08/2025
Last modified:  17/11/2025
Author:         Wim Matthyssen
Version:        1.1
PowerShell:     Azure PowerShell and Azure Cloud Shell
Requires:       PowerShell Az (v10.4.1)
Action:         Change variables where needed to fit your needs.
Disclaimer:     This script is provided "As Is" with no warranties.

.EXAMPLE
Connect-AzAccount
Get-AzTenant (if not using the default tenant)
Set-AzContext -tenantID "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx" (if not using the default tenant)
.\Create-Decommissioned-Management-group.ps1 -ManagementGroupName <"your Management group name here"> 

Example: .\Create-Decommissioned-Management-group.ps1 -ManagementGroupName "mg-myh-decommissioned"

.LINK
#>

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Parameters

param(
    [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $managementGroupName
)

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$companyFullName = "myhcjourney"
$companyManagementGroupName = "mg-" + $companyFullName

# Time, colors, and formatting
$currentTime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"
$foregroundColor1 = "Green"
$foregroundColor2 = "Yellow"
$foregroundColor3 = "Red"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "
$writeEmptySpaces = " " * 1

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Suppress Azure PowerShell breaking change warning messages to avoid unnecessary output.

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true | Out-Null
Update-AzConfig -DisplayBreakingChangeWarning $false | Out-Null
Update-AzConfig -DisplayRegionIdentified $false | Out-Null
$WarningPreference = "SilentlyContinue"

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script started.

Write-Host ($writeEmptyLine + "# Script started. Without errors, it can take up to 2 minutes to complete" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor1 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Permission checks.

try {
    $context = Get-AzContext
    if ($null -eq $context) {
        Write-Host ($writeEmptyLine + "# Error: Not connected to Azure. Please run Connect-AzAccount first." + $writeSeperatorSpaces + $currentTime) `
        -foregroundcolor $foregroundColor3 $writeEmptyLine
        exit 1
    }
    
    Get-AzManagementGroup -ErrorAction Stop | Out-Null
} catch {
    Write-Host ($writeEmptyLine + "# Error: Insufficient permissions or not connected to Azure: $($_.Exception.Message)" + $writeSeperatorSpaces + $currentTime) `
    -foregroundcolor $foregroundColor3 $writeEmptyLine
    exit 1
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Get parent Management group.

try {
    $allManagementGroups = Get-AzManagementGroup
    $companyParentGroup = $allManagementGroups | Where-Object {$_.DisplayName -eq $companyManagementGroupName}
    
    if ($null -eq $companyParentGroup) {
        Write-Host ($writeEmptyLine + "# Parent management group '$companyManagementGroupName' not found in list:" + $writeSeperatorSpaces + $currentTime) `
        -foregroundcolor $foregroundColor3 $writeEmptyLine
        Write-Host "Existing Management Groups:"
        $allManagementGroups | Select-Object DisplayName, Name | Format-Table
        throw "Parent management group '$companyManagementGroupName' not found"
    }
    
    # Explicitly fetch parent with -Expand to populate Children
    $companyParentGroup = Get-AzManagementGroup -GroupName $companyParentGroup.Name -Expand -ErrorAction Stop
    
    Write-Host ($writeEmptyLine + "# Found parent management group '$($companyParentGroup.DisplayName)'" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine
} catch {
    Write-Host ($writeEmptyLine + "# Error: $($_.Exception.Message)" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor3 $writeEmptyLine
    exit 1
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create the decommissioned Management Group if it does not exist.

try {
    # Check if group already exists by searching children
    $existing = $null
    
    if ($null -ne $companyParentGroup.Children -and $companyParentGroup.Children.Count -gt 0) {
        $existing = $companyParentGroup.Children | Where-Object {
            ($_.DisplayName -ne $null) -and
            ($_.DisplayName.Trim().ToLower() -eq $managementGroupName.Trim().ToLower())
        } | Select-Object -First 1
    }

    if ($null -ne $existing) {
        Write-Host ($writeEmptyLine + "# Management group '$managementGroupName' already exists" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine
        Write-Host $writeEmptySpaces "DisplayName: $($existing.DisplayName)" -foregroundcolor $foregroundColor2
        Write-Host $writeEmptySpaces "Name:        $($existing.Name)" -foregroundcolor $foregroundColor2
        Write-Host $writeEmptySpaces "Id:          $($existing.Id)" -foregroundcolor $foregroundColor2 $writeEmptyLine
    } else {
        # Group doesn't exist, create it
        $decommissionedManagementGroupGuid = (New-Guid).Guid
        $newGroup = New-AzManagementGroup `
            -GroupName $decommissionedManagementGroupGuid `
            -DisplayName $managementGroupName `
            -ParentId $companyParentGroup.Id `
            -ErrorAction Stop

        Write-Host ($writeEmptyLine + "# Management group '$managementGroupName' created successfully" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine
        Write-Host ($writeEmptyLine + "# New management group details:") -foregroundcolor $foregroundColor2 $writeEmptyLine
        Write-Host $writeEmptySpaces "DisplayName: $($newGroup.DisplayName)"
        Write-Host $writeEmptySpaces "Name:        $($newGroup.Name)"
        Write-Host $writeEmptySpaces "Id:          $($newGroup.Id)" $writeEmptyLine
    }

} catch {
    Write-Host ($writeEmptyLine + "# Critical Error: $($_.Exception.Message)" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor3 $writeEmptyLine
    exit 1
}

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed.

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor1 $writeEmptyLine

## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------