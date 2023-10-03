###########################
# NAME: Workstation PING  #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/20     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# This purpose of this script is to check the status of all workstations.
# We will return an "online" or "offline" accordingly.

# PowerShell variables.
$test_msg = 'Pre-connecting to...' # The pre-connection to a workstation.
$Export_Csv = 'C:\workstation\AD_OnlineOffline.csv' # This can be changed if need be.

# Specify the base to search within OU IF required.
$search_base = ''

if (!($search_base)) {
    $workstation = Get-ADComputer -Filter * -Properties Description, OperatingSystem, CanonicalName, LastLogonDate, whenCreated
}
else {
    $workstation = Get-ADComputer -Filter * -Properties Description, OperatingSystem, CanonicalName, LastLogonDate, whenCreated -SearchBase $search_base
}

# Here is the output from the search.
$OutputResults = @()
foreach ($workstation in $workstations) {
    Write-Progress -Activity "$test_msg" -Status $workstation.Name -PercentComplete ($workstations.IndexOf($workstation) / $workstations.Count * 100)

    # Here are the output objects "ooObj".
    $ooObj = New-Object -Type psobject
    $ooObj | Add-Member -MemberType NoteProperty -Name 'Workstation' -Value $workstation.Name

    # Test the connection.
    $hostHello = Test-Connection -ComputerName $workstation.DNSHostName -Count 1 -Quiet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    if (!($hostHello)) {
        $hostHello = Test-Connection -ComputerName $workstation.DNSHostName -Count 2 -Quiet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }

    # Is the workstation online?
    if ($hostHello) {
        $ooObj | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Online'
    }
    else {
        # Is the workstation offline?
        $ooObj | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Offline'
    }

    # Adding some details to the output csv.
    $ooObj | Add-Member -MemberType NoteProperty -Name 'Description' -Value $workstation.Description
    $ooObj | Add-Member -MemberType NoteProperty -Name 'OperatingSystem' -Value $workstation.OperatingSystem
    $ooObj | Add-Member -MemberType NoteProperty -Name 'CanonicalName' -Value $workstation.CanonicalName
    $ooObj | Add-Member -MemberType NoteProperty -Name 'LastLogonDate' -Value $workstation.LastLogonDate
    $ooObj | Add-Member -MemberType NoteProperty -Name 'whenCreated' -Value $workstation.whenCreated
    $OutputResults += $ooObj
    $ooObj
}

# Time to export the results into a CSV file.
$OutputResults | Export-Csv -Path $Export_Csv -NoTypeInformation