###########################
# NAME: Windows Ducky     #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/20     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# The purpose of this script is to remove old files after "X" amount of days.

# Specify the location to remove the files from. i.e.: C:\exchange\mailbox.log.
$TgtPath = @('', '')

# Enter a wildcard to match with the files you want to remove. i.e.: *.txt | *.log | *.cfg
$wildcard = ''

# Specify the amount of days you want to keep. i.e.: 7.
$days = ''

# Time to determine the "last write" to the file(s).
$JudgementDay = (Get-Date).AddDays(-$days)

# Time to find and delete them.
foreach ($TgtPath in $TgtPath) {
    $files = Get-ChildItem $TgtPath -Include $wildcard -Recurse | Where-Object { $_.LastWriteTime -le "$JudgementDay" }
    # Delete the file(s).
    foreach ($file in $files) {
        if ($file -ne $null) {
            Remove-Item $file.FullName | Out-Null
        }
    }
}