###########################
# NAME: AD FSMO Switch    #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/20     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# The purpose of this script is to transfer the FSMO roles from one server to another.
# It is best to "Run-as Administrator" for this script.

<#
RMRKs: Remember to update the NTP settings after migrating the FSMO roles to a new DC.
The old DC's NTP settings need to be set to "AUTO". That way it can sync to the new DC.
If the settings are left as is, then there will be a time drift in the domain.#>

# PowerShell variables
$adm_msg = 'Please enter the domain admin credentials.' # We will enter the domain admin credentials.

# Time to import the AD mod and start the work.
Import-Module -Name ActiveDirectory
$new_dc = ''

# We will supply the domain admin information now.
$get_adm_cred = Get-Credential -Message "$adm_msg"

# Retrieving a list of all DC.
$domain_controller = Get-ADDomainController -Filter *

# List all of the FSMO roles. Normally the roles are on a single server.
$schemaPrime = ($domain_controller | Where-Object { $_.OperationMasterRoles -contains 'SchemaMaster' }).Name
$ridPrime = ($domain_controller | Where-Object { $_.OperationMasterRoles -contains 'RIDMaster' }).Name
$infrastructurePrime = ($domain_controller | Where-Object { $_.OperationMasterRoles -contains 'InfrastructureMaster' }).Name
$domainNaming = ($domain_controller | Where-Object { $_.OperationMasterRoles -contains 'DomainNamingMaster' }).Name
$pdcEmulator = ($domain_controller | Where-Object { $_.OperationMasterRoles -contains 'PDCEmulator' }).Name

# Time to migrate the roles to the new server.
Move-ADDirectoryServerOperationMasterRole -Server $schemaPrime -Identity $new_dc -OperationMasterRole SchemaMaster -Credential $get_adm_cred -Confirm:$false
Move-ADDirectoryServerOperationMasterRole -Server $ridPrime -Identity $new_dc -OperationMasterRole RIDMaster -Credential $get_adm_cred -Confirm:$false
Move-ADDirectoryServerOperationMasterRole -Server $infrastructurePrime -Identity $new_dc -OperationMasterRole InfrastructureMaster -Credential $get_adm_cred -Confirm:$false
Move-ADDirectoryServerOperationMasterRole -Server $domainNaming -Identity $new_dc -OperationMasterRole DomainNamingMaster -Credential $get_adm_cred -Confirm:$false
Move-ADDirectoryServerOperationMasterRole -Server $pdcEmulator -Identity $new_dc -OperationMasterRole PDCEmulator -Credential $get_adm_cred -Confirm:$false