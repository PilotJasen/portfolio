###########################
# NAME: Get AzureAD Roles #
# AUTHOR: DesertRatz      #
# CREATED: 2023/03/27     #
# (C) 2022-2023           #
###########################

# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# The purpose of this script is to retrieve the AzureAD roles.

# We will set the output file now.
$outFile = 'C:\temp\AzureADAssignedRoles.csv'

# We will now import and connect to AzureAD.
Import-Module -Name AzureAD
Connect-AzureAD

# We will search for all AzureAD role definitions.
$roleDef = Get-AzureADMSRoleDefinition | Where-Object { $_.Id -ne 'a0b1b346-4d3e-4e8b-98f8-753987be4970' }

# We will create an output for the roles.
$GetAssignedRoles = @()

# We will set the progress to 0.
$i = 0

# We will run through the role definitions.
foreach ($roleDef in $roleDefs) {
    # Print the progress bar.
    Write-Progress -Activity 'Processing...' -Status $roleDef.DisplayName -PercentComplete ((++$i / $roleDef.Count) * 100)

    # We will retrieve the assigned role definitions now.
    $roleAssignment = Get-AzureADMSRoleAssignment -All $true -Filter "roleDefinitionId eq '$($roleDef.Id)'"

    # Time to determine the role assignments.
    if ($roleAssignment) {
        # Retrieve the AzureAD assigned objects.
        $AzureADObjects = Get-AzureADObjectByObjectId -ObjectIds $roleAssignment.PrincipalId

        # We will add an additional object to the AzureAD output array.
        foreach ($AzureADObjects in $AzureADObjects) {
            $AzureAssignedRoles += [PSCustomObject]@{
                'DisplayName'       = $AzureADObjects.DisplayName;
                'UserPrincipalName' = $AzureADObjects.UserPrincipalName;
                'RoleName'          = $roleDef.DisplayName;
            }
        }
    }
}

# Send the output to a CSV file.
$GetAssignedRoles | Sort-Object -Property DisplayName | Export-Csv -NoTypeInformation -Path $outFile

# Goodbye.
Disconnect-AzureAD