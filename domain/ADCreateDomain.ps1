###########################
# NAME: ADCreate Domain   #
# AUTHOR: DesertRatz      #
# CREATED: 2023/07/22     #
# (C) 2022-2023           #
###########################

# The purpose of this script is to automate the creation of the AD Domain.

# Replace "DOMAIN" and "domain.name" for your own domain.

Import-Module ADDSDeployment
Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath 'C:\Windows\NTDS\db' `
    -DomainMode 'WinThreshold' `
    -DomainName 'domain.name' `
    -DomainNetbiosName 'DOMAIN' `
    -ForestMode 'WinThreshold' `
    -InstallDns:$true `
    -LogPath 'C:\Windows\NTDS\logs' `
    -NoRebootOnCompletion:$false `
    -SysvolPath 'C:\Windows\SYSVOL' `
    -Force:$true
