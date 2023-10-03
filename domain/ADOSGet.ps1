###########################
# NAME: AD OS Get Tool    #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/20     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# We will gather all DC in the domain and show the current OS they are running.
$adWorkstations = Get-ADComputer -Filter * -Properties OperatingSystem

# Retrieve the OS information from all workstations and display them here.
$OSes = $adWorkstations.OperatingSystem | Sort-Object -Unique

# Print the OSes and count the AD computers that are running them.
foreach ($OSes in $OS) {
    $workstations = ($adWorkstations | Where-Object { $_.OperatingSystem -eq $OSes }).Name
    Write-Host ([string]$workstations.Count + 'Name' + $OSes + '.')
}