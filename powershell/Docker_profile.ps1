###########################
# NAME: PowerShell Alias  #
# AUTHOR: DesertRatz      #
# CREATED: 2024/09/12     #
# (C) 2024-2026           #
###########################

# Query Docker containers.
function ds {
	docker ps
}
Set-Alias MyAlias ds

# Start Portainer.
function dsp {
	docker start portainer
}
Set-Alias MyAlias dsp

# Remove PowerShell history.
function rpsh {
	Remove-Item (Get-PSReadLineOption).HistorySavePath
}
Set-Alias MyAlias rpsh