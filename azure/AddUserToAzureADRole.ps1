###########################
# NAME: Add AAD To Role   #
# AUTHOR: DesertRatz      #
# CREATED: 2023/03/27     #
# (C) 2022-2023           #
###########################

# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# The purpose of this script is to add users to an AzureAD based role.

# Name of the user you want to use.
$roleUsr = ''

# Name of the role.
$roleName = ''

# We will import the AzureAD module and connect to it.
Import-Module AzureAD
Connect-AzureAD

# We will retrieve the user.
$roleMember = Get-AzureADUser -ObjectId $roleUsr

# We will retrieve the AzureAD role.
$role = Get-AzureADDirectoryRole | Where-Object { $_.displayName -eq $roleName }

# If the role does not exist, then use a template (optional).
if (!($role)) {
    # Use the role template.
    $roleTemp = Get-AzureADDirectoryRoleTemplate | Where-Object { $_.displayName -eq $roleName }
    Enable-AzureADDirectoryRole -RoleTemplateId $roleTemp.ObjectId

    # We will search for the roles again.
    $role = Get-AzureADDirectoryRole | Where-Object { $_.displayName -eq $roleName }
}

# We will add the user to the role.
Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $roleMember.ObjectId

# We will refresh and print the new role for the user.
Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | Get-AzureADUser

# Goodbye.
Disconnect-AzureAD