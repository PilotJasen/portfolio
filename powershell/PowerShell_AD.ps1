#########################
# NAME: PowerShell AD	#
# AUTHOR: DesertRatz	#
# CREATED: 2022/12/04	#
# (C) 2022-2026			#
#########################

# Query FSMO roles for domain.
function ndf {
	netdom query fsmo
}
Set-Alias MyAlias ndf

# Query all users for computer/domain.
function nu {
	net user
}
Set-Alias MyAlias nu

# Query all users for domain.
function gdu {
	Get-ADUser -Filter *
}
Set-Alias MyAlias gdu

# Query all user properties for domain (full).
function gdpf {
	Get-ADUser -Filter * -Properties *
}
Set-Alias MyAlias gdpf

# Query all user properties for domain (short).
function gdps {
	Get-ADUser -Filter * -Properties * | Select-Object Name, DisplayName, SamAccountName, UserPrincipalName
}
Set-Alias MyAlias gdps

# Query all users last logon for domain (full).
function gdlf {
	Get-ADUser -filter * -Properties 'LastLogonDate' | Select-Object name, LastLogonDate
}

Set-Alias MyAlias gdlf

# Query all users last logon for domain (short).
function gdls {
	Get-ADUser -Filter * -Properties lastLogon | Select-Object samaccountname,
	@{Name = 'lastLogon'; Expression = { [datetime]::FromFileTime($_.'lastLogon') } }
}

Set-Alias MyAlias gdls

# Clear DNS Cache for computer.
function cdc {
	Clear-DnsClientCache
}
Set-Alias MyAlias cdc

# Query all workstations for computer/domain
function gwc {
	Get-ADComputer -Filter *
}
Set-Alias MyAlias gwc

# Remove PowerShell history.
function rpsh {
	Remove-Item (Get-PSReadLineOption).HistorySavePath
}
Set-Alias MyAlias rpsh

# Start Notepad++ to edit Windows Aliases.
function npp {
	start notepad++ C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1
}
Set-Alias MyAlias npp