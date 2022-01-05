<#
.SYNOPSIS

A script used to configure a Point-to-Site (P2S) VPN Connection to an existing VNet in Azure using Azure certificate authentication. 

.DESCRIPTION

A script used to configure a Point-to-Site (P2S) VPN Connection to an existing VNet in Azure using Azure certificate authentication.
First of all some checks will be performed, to see if the VPN gateway variable is declared correctly and/or the VPN gateway resource does exist in the Azure environment.
Then the script will also check if the root certificate is present in the C:\Temp folder.
If one of the checks fails, the script will be exited. 
But if all checks are OK, the script will continue with adding the VPN client address pool and the client root certificate to the VPN gateway. 
Then the Temp folder is created on the C: drive, if the folder not already exists.
And at the end, the VPN client configuration files are generated and downloaded (vpnclientconfiguration.zip) to the C:\Temp folder.
 
.NOTES

Filename:       Configure-P2S-VPN-to-an-existing-VNet-using-Azure-certificate-authentication.ps1
Created:        05/01/2022
Last modified:  05/01/2021
Author:         Wim Matthyssen
PowerShell:     Azure Cloud Shell or Azure PowerShell
Version:        Install latest Azure Powershell modules (at least Az version 5.9.0 and Az.Network version 4.7.0 is required)
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "As IS" with no warranties.

.EXAMPLE

.\Configure-P2S-VPN-to-an-existing-VNet-using-Azure-certificate-authentication.ps1

.LINK


#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$rgNetworkSpoke = #<your VNet rg here> The Azure resource group in which your existing VNet is deployed. Example: "rg-hub-myh-networking"
$gatewayName = #<your virtual network gateway name here> The existing virtual network gateway. Example: "vpng-hub-myh-weu"
$vpnClientAddressPool = #<your VPN client address pool here> The VPN client address pool from which the VPN clients receive an IP address. Example: "172.16.101.0/24"

$rootCertName = #<your root certificate name here> The name of the root certificate. Example: "p2s-myh-root-cert"
$rootCertBase64Path = #<your exported root cert (.CER) file path here> The file path to the exported root Base-64 encoded X.509 (.CER) file. Example: "C:\Temp\$rootCertName.cer"
$tempFolderName = "Temp"
$tempFolder = "C:\" + $tempFolderName +"\"
$vpnClientConfigZip = "vpnclientconfiguration.zip"
$vpnClientConfigDestinationFolder = $tempFolder + $vpnClientConfigZip

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if running as Administrator, otherwise exit the script

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdministrator -eq $false) {
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    exit
}
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Start script execution

Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 6 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check VPN gateway and root certificate 

# Check the VPN gateway variable and the existence of the resource. If it is not declared correctly or the resource is not there, exit the script
try {
    $gateway = Get-AzVirtualNetworkGateway -ResourceGroupName $rgNetworkSpoke -Name $gatewayName -ErrorAction Stop
} catch {
    Write-Host ($writeEmptyLine + "# An error occurred: Check the $gatewayName variable and the existence of the resource in the environment" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine

    Write-Host ($writeEmptyLine + "# The script will be stopped. Please fix the error, and rerun the script" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine

    exit 
}

# Check if the root certificate is available in the Temp folder, otherwise exit the script
If(!(test-path $rootCertBase64Path -PathType Leaf))
{   
Write-Host ($writeEmptyLine + "# The Client root certificate $rootCertName can not be found at the specified location" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

Write-Host ($writeEmptyLine + "# The script will be stopped. Please fix the error, and rerun the script" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

exit
}

Write-Host ($writeEmptyLine + "# VPN Gateway $gatewayName and root certificate $rootCertName checks completed with succes" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Add the VPN client address pool

Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gateway -VpnClientAddressPool $vpnClientAddressPool

Write-Host ($writeEmptyLine + "# VPN client address pool $vpnClientAddressPool added to the virtual gateway $gatewayName" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Add the client root certificate to the virtual gateway

$cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($rootCertBase64Path)
$base64Cert = [system.convert]::ToBase64String($cert.RawData)

Add-AzVpnClientRootCertificate -PublicCertData $base64Cert -ResourceGroupName $rgNetworkSpoke -VirtualNetworkGatewayName $gatewayName -VpnClientRootCertificateName $rootCertName

Write-Host ($writeEmptyLine + "# Client root certificate $rootCertName added to the virtual gateway $gatewayName" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create C:\Temp folder if not exists

If(!(test-path $tempFolder))
{
New-Item -Path "C:\" -Name $tempFolderName -ItemType $itemType -Force | Out-Null
}

Write-Host ($writeEmptyLine + "# $tempFolderName folder available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Generate VPN client configuration files and download them in the C:\Temp folder

# Generate VPN client configuration files
$vpnClientConfig = New-AzVpnClientConfiguration -ResourceGroupName $rgNetworkSpoke -Name $gatewayName -AuthenticationMethod "EapTls"

# Download VPN client configuration files (vpnclientconfiguration.zip)
Import-Module BitsTransfer
Start-BitsTransfer -Source $vpnClientConfig.VPNProfileSASUrl -Destination $vpnClientConfigDestinationFolder

Write-Host ($writeEmptyLine + "# VPN configuration files generated and downloaded into $tempFolder" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
