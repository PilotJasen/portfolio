#########################
# NAME: PowerShell Aka	#
# AUTHOR: DesertRatz	#
# CREATED: 2024/10/25	#
# (C) 2024-2026			#
#########################

# Clear DNS Cache for computer.
function cdc {
	Clear-DnsClientCache
}
Set-Alias MyAlias cdc

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

# Update PowerShell help (SilentlyContinue)
function uph {
	Update-Help -UICulture en-US -Force -ErrorAction SilentlyContinue
}
Set-Alias MyAlias uph