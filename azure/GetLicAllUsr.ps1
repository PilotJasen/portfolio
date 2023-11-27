###########################
# NAME: Get AzureAD Lic   #
# AUTHOR: DesertRatz      #
# CREATED: 2023/03/27     #
# (C) 2022-2023           #
###########################

# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# The purpose of this script is to retrieve the AzureAD licenses for all users.

# We will set the output info here:
$outFilePath = 'c:\temp\'
$outFileName = 'AzureADLic.csv'

# We will import and connect to AzureAD.
Import-Module AzureAD
Connect-AzureAD

# We will retrieve the license details.
$AzureSku = Get-AzureADSubscribedSku

# We will import a list of users.
$user = Get-AzureADUser -All $true

# Retrieve the licenses for each user and determine what they are used for.
$UsrLic =@()
foreach ($user in $users) {
    $AzureLic =@()
    foreach ($lic in $user.AssignedLicenses.SkuId) {
        $AzureLic += ($AzureSku | Where-Object {$_.SkuId -eq $license}).SkuPartNumber
    }
    $usrAuth = [PSCustomObject]@{
        'UserName' = $user.UserPrincipalName
        'AssignedLicenses' = (($AzureLic | Sort-Object) -join ';')
    }
    $UsrLic += $usrAuth
}

# We will send the output to a CSV file.
$outFile = $outFilePath + $outFileName
$UsrLic | Export-Csv -Path $outFile -NoTypeInformation

# Goodbye.
Disconnect-AzureAD