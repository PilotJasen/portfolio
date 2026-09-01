###########################
# NAME: PowerShell HyperV #
# AUTHOR: DesertRatz      #
# CREATED: 2022/11/21     #
# (C) 2022-2026           #
###########################

# Rename file to "Microsoft.PowerShell_profile.ps1
# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# Query VM states (short).
function gvs {
	Get-VM
}
Set-Alias MyAlias gvs

# Query VM states (full).
function gvf {
	Get-VM | Format-List *
}
Set-Alias MyAlias gvf

# Query VM host info (short).
function gvms {
	Get-VMHost
}
Set-Alias MyAlias gvms

# Query VM host info (full).
function gvmf {
	Get-VMHost | Format-List
}
Set-Alias MyAlias gvmf

# Power On VM.
function pwro {
	Start-VM
}

Set-Alias MyAlias pwro

# Power Off VM.
function pwrs {
	Stop-VM
}
Set-Alias MyAlias pwrs

# Remove PowerShell history.
function rpsh {
	Remove-Item (Get-PSReadLineOption).HistorySavePath
}
Set-Alias MyAlias rpsh

# Remove EFI file from VM.
function refi {
	Get-VMFirmware -VMName $VMName | ForEach-Object { Set-VMFirmware -BootOrder ($_.Bootorder | Where-Object { $_.BootType -ne 'File' }) $_ }
}
Set-Alias MyAlias refi