###########################
# NAME: Azure Del Res     #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/20     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# The purpose of this script is to delete Azure based resource groups.

# Time to start the Azure connection.
Import-Module -Name AZ
Connect-AzAccount -UseDeviceAuthentication

# Specify what resource you want to delete.
$subscriptionName = ''

# What groups do you want to exclude?
$GrpToExclude = @('')

# Time to change to the relevant subscription.
Set-AzContext -Subscription $subscriptionName

# We will now retrieve the group info.
$GrpToPurge = (Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -notin $GrpToExclude}).ResourceGroupName

# Time to remove them.
foreach ($GrpToPurge in $GrpToPurge) {
    Remove-AzResourceGroup -Name $GrpToPurge
}

# Goodbye.
Disconnect-AzAccount