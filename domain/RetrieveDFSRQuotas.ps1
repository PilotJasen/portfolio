###########################
# NAME: Retrieve DFSR     #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/21     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# The purpose of this script is to retrieve the DFSR quotas.

# Specify the location to save the output file.
# This can be changed as needed.
$OutPutCsv = 'C:\dfsr\DfsrStagingResult.csv'

# We will retrieve the DFS replicated folder(s).
$DfsrRepFld = Get-DfsrReplicatedFolder

# We will create a blank table to hold the item(s).
$DfsBlank = @()

# Cycle through the shares.
foreach ($DfsrRepFld in $DfsrRepFolders) {
    # Retrieve the top biggest files from the share(s).
    # The default value is "32". This can be changed as needed.
    $BigFiles = Get-ChildItem -Path $DfsrRepFld.DfsnPath -Recurse | Sort-Object -Property Length -Descending | Select-Object -First 32

    # Calculate the sizes of the top "32" files.
    $CalSum = $BigFiles | Measure-Object -Property Length -Sum

    # Convert it to MB and round up.
    $StageQuotaMB = [math]::Ceiling($CalSum.Sum / 1MB)

    # We will add the results into a table.
    $DfsrTable += [PSCustomObject]@{
        'FolderName'   = $DfsrRepFld.FolderName;
        'DfsnPath'     = $DfsrRepFld.DfsnPath;
        'StageQuotaMB' = $StageQuotaMB;
    }
}

# Export the results to a CSV file.
$DfsDetails | Export-Csv -Path $OutPutCsv