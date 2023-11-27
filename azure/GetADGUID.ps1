###########################
# NAME: Get AD GUID       #
# AUTHOR: DesertRatz      #
# CREATED: 2023/03/29     #
# (C) 2022-2023           #
###########################

# The purpose of this script is to retrieve the GUID from O365 and convert it to AD GUID.

# We will import Azure AD module and connect.
Import-Module AzureAD
Connect-AzureAD

# Specify the ID we are using.
$usrUPN = Read-Host -Prompt "Please enter your username. Format 'user@domain'."

# We will convert O365 ImmutableID to AD GUID.
$immutableID = (Get-AzureADUser -ObjectId $usrUPN).ImmutableID
[GUID][System.Convert]::FromBase64String($immutableID)

# Goodbye.
Disconnect-AzureAD