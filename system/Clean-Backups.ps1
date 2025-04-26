#########################
# NAME: Clean-Backups	#
# AUTHOR: DesertRatz	#
# CREATED: 2025/03/23	#
# (C) 2022-2025			#
#########################

# Define the directory where backup folders are located
$backupDirectory = "DRV-LETTER:\Path\To\Backups"  # Change this to the actual backup directory path

# Define the number of days before backups are considered old and should be deleted
$daysOld = 30  # You can adjust this value as needed

# Get the current date
$currentDate = Get-Date

# Try to get all the folders in the backup directory
try {
	$backupFolders = Get-ChildItem -Path $backupDirectory -Directory | Where-Object { $_.Name -match "_\d{8}$" }
} catch {
	Write-Host "Error accessing the backup directory: $_"
	exit 1
}

# Loop through each backup folder
foreach ($folder in $backupFolders) {
	try {
		# Extract the date from the folder name (assuming the format is _YYYYMMDD)
		$folderDateString = $folder.Name.Substring($folder.Name.Length - 8)
		$folderDate = [datetime]::ParseExact($folderDateString, 'yyyyMMdd', $null)

		# Calculate the difference between the current date and the folder's date
		$age = $currentDate - $folderDate

		# If the folder is older than the specified number of days, delete it
		if ($age.Days -ge $daysOld) {
			Write-Host "Deleting old backup folder: $($folder.Name)"
			Remove-Item -Path $folder.FullName -Recurse -Force
		} else {
			Write-Host "Skipping folder (not old enough): $($folder.Name)"
		}
	} catch {
		Write-Host "Error processing folder '$($folder.Name)': $_" -ForegroundColor Red
	}
}