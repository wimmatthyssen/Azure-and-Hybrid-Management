<#
.SYNOPSIS

A script used to generate a new self-signed root certificate and a client certificate for use with an Azure Point-to-Site (P2S) VPN. 

.DESCRIPTION

A script used to generate a new self-signed root certificate and a client certificate for use with an Azure P2S VPN. 
The newly generated self-signed root certificate uses the default provider, which is the Microsoft Software Key Storage Provider, and it is stored in the user MY store. 
Next to that the self-signed root certificate also uses an RSA asymmetric key with a key size of 2048 bits and expires after 3 months.
The client certificate is generated from the self-signed root certificate and is also stored in the user MY store.
After it is generatd the client certificate is exported as a PFX file to the C:\Temp folder. If the C:\Temp folder, which is created if it not already exsists.
The .pfx file containes the root certificate information and the entire certificate chain, and can be used and installed on another client computer to authenticate.

Keep in mind that each client computer that you want to connect to a VNet with a P2S VPN connection must have a client certificate installed. 
 
.NOTES

Filename:       Generate-authenticaton-certificates-P2S-VPN.ps1
Created:        20/12/2021
Last modified:  20/12/2021
Author:         Wim Matthyssen
PowerShell:     Azure Cloud Shell or Azure PowerShell
Version:        Install latest Azure Powershell modules (at least Az version 5.9.0 and Az.Network version 4.7.0 is required)
Action:         Change variables were needed to fit your needs. 
Disclaimer:     This script is provided "As IS" with no warranties.

.EXAMPLE

.\Generate-authenticaton-certificates-P2S-VPN.ps1

.LINK

https://wmatthyssen.com/2021/06/02/azure-bastion-azure-powershell-deployment-script/
#>

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Variables

$rootCertName = "p2s-myh-root-cert"
$clientCertName = "p2s-myh-client-cert"
$certStoreName = "cert:\currentuser\my"
$certValidMonths = "3"
$tempFolderName = "Temp"
$tempFolder = "C:\" + $tempFolderName +"\"
$clientCertPassword = "P@ssw0rd" | ConvertTo-SecureString -AsPlainText -Force

$global:currenttime= Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Check if running as Administrator, otherwise close the PowerShell window

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdministrator -eq $false) {
    Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
    Start-Sleep -s 5
    exit
}
 
## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Start script execution

Write-Host ($writeEmptyLine + "# Script started" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 
 
##-------------------------------------------------------------------------------------------------------------------------------------------------------

## Create the self-signed root certificate which expires after 3 months

$rootCert = New-SelfSignedCertificate -Type Custom `
          -KeySpec Signature `
          -Subject "CN=$rootCertName" `
          -KeyExportPolicy Exportable `
          -HashAlgorithm sha256 `
          -KeyLength 2048 `
          -CertStoreLocation $certStoreName `
          -KeyUsageProperty Sign `
          -KeyUsage CertSign `
          -NotAfter (Get-Date).AddMonths($certValidMonths)

Write-Host ($writeEmptyLine + "# Root certificate $rootCertName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Generate the client certificate which expires after 3 months

$clientCert = New-SelfSignedCertificate -Type Custom `
            -DnsName P2SChildCert `
            -KeySpec Signature `
            -Subject "CN=$clientCertName" `
            -KeyExportPolicy Exportable `
            -HashAlgorithm sha256 `
            -KeyLength 2048 `
            -CertStoreLocation $certStoreName `
            -Signer $rootCert `
            -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") `
            -NotAfter (Get-Date).AddMonths($certValidMonths)

Write-Host ($writeEmptyLine + "# Client certificate $clientCertName created" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Create C:\Temp folder if not exists

If(!(test-path $tempFolder))
{
New-Item -Path "C:\" -Name $tempFolderName -ItemType $itemType -Force | Out-Null
}

Write-Host ($writeEmptyLine + "#" + $writeSpace + $tempFolderName + $writeSpace + "folder available" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Export the client certificate to a PFX file in the C:\Temp folder

Export-PfxCertificate -Cert $clientCert -FilePath C:\Temp\"$clientCertName.pfx" -Password $clientCertPassword

Write-Host ($writeEmptyLine + "# Client certificate $clientCertName PFX file created in the Temp folder" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine

## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Write script completed

Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine 

##-------------------------------------------------------------------------------------------------------------------------------------------------------
