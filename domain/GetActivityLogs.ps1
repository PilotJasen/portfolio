###########################
# NAME: Activity Logs     #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/21     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# The purpose of this script is to retrieve the activity logs for a specified user.

# We will specify a start/end value (i.e.: YYYY_MMDD_TThhmm).
$TimeStart = '' # Specify the start time.
$TimeStop = '' # Specify the end time.

# Specify the user you want to export the logs from.
$usrName = ''

# Specify the location you want to create the CSV file.
$OutPutFile = 'C:\temp\AzureActivityLogs.cs' # You can change the location as need be.

# We will specify the RegEx to locate the info we need.
$subscriptionRegEx = '^.*$'

# Time to start the Azure connection.
Import-Module -Name AZ
Connect-AzAccount

# Time to start our array.
$OutPutEntries = @()
foreach ($subscription in $subscriptions) {
    # We will switch to it now.
    $null = Set-AzContext -Subscription $subscription

    # Time to get the activity logs.
    $ActLogs = Get-AzActivityLog -StartTime $TimeStart -EndTime $TimeStop -Caller $usrName -DetailedOutput

    foreach ($activity in $ActLogs) {
        # We will create the "resourceType" manually since the "$ActLogs" command currently returns an empty field.
        $splitString = $activity.Properties.Content.entity.Split('/')
        $resourceType = $splitString[$splitString.IndexOf('providers') + 1]
        if ($splitString[$splitString.Index('providers') + 2]) {
            $resourceType += '/' + $splitString[$splitString.IndexOf('providers') + 2]
        }
        # We will create the table for the output array.
        $OutPutEntries += [PSCustomObject]@{
            CorrelationId     = $activity.CorrelationId;
            OperationName     = $activity.OperationName;
            Status            = $activity.Status;
            EventCategory     = $activity.EventCategory;
            Level             = $activity.Level
            Timestamp         = $activity.Timestamp
            SubscriptionId    = $activity.SubscriptionId
            IpAddress         = $activity.Claims.Content.ipaddr;
            InitiatedBy       = $activity.Caller;
            ResourceType      = $resourceType;
            ResourceGroupName = $activity.ResourceGroupName;
            Resource          = $activity.ResourceId;
        }
    }
}

# Time to export the results into a CSV file.
$OutPutEntries | Sort-Object -Property TimeStamp | Export-Csv -Path $OutPutFile -NoTypeInformation

# Goodbye.
Disconnect-AzAccount