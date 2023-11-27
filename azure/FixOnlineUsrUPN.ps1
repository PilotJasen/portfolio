###########################
# NAME: Fix User UPN      #
# AUTHOR: DesertRatz      #
# CREATED: 2023/03/27     #
# (C) 2022-2023           #
###########################

# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# The purpose of this script is to fix the user's UPN if something was not synced correctly.

# We will import the AzureAD module and connect to it.
Import-Module AzureAD
Connect-AzureAD

# What user are we changing the UPN for?
$srcUPN = Read-Host -Prompt 'Enter the UPN you wish to change. Format is "user@domain".'

# Supply the new UPN name here.
$destUPN = Read-Host -Prompt 'Enter the new UPN here. Format is "user@domain".'

# We will update the UPN in AzureAD now.
Set-AzureADUser -ObjectId $srcUPN -UserPrincipalName $destUPN

# Goodbye
Disconnect-AzureAD