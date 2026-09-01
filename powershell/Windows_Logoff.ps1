#########################
# NAME: Windows Logoff	#
# AUTHOR: DesertRatz	#
# CREATED: 2025/01/15	#
# (C) 2025-2026			#
#########################

# PowerShell script to log off the current user without interaction

# Get the current user session ID
$sessionId = (query user | Select-String -Pattern $env:USERNAME).ToString().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)[2]

# Log off the user session
logoff $sessionId