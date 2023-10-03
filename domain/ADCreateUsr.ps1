###########################
# NAME: ADCreate User     #
# AUTHOR: DesertRatz      #
# CREATED: 2023/06/21     #
# (C) 2022-2023           #
###########################

# The purpose of this script is to automate the creation of the AD users.

# God powers.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy ByPass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
    exit;
}

# PowerShell custom vars.
$DCName = server.domain.com # Replace this with your domain information.
$SMTP_Port_Num = 587 # Replace this with your SMTP information.

$locPcName = $env:COMPUTERNAME
Write-Output '##################'
Write-Output '# AD Create User #'
Write-Output '##################'

Write-Output ''

Write-Output '##########################################'
Write-Output '# Ensure that you created the user email #'
Write-Output '# in the cPanel before using this script #'
Write-Output '##########################################'

# We will check to see if PS-Remote is enabled. If the feature is not then we will enable it.
if (Get-WmiObject -Class win32_service | Where-Object { $_.name -like 'WinRM' }) {
    Write-Output 'PS-Remote is already enabled.'
    Write-Output "`n"
}
else {
    Write-Output 'In the process of enabling PS-Remote...'
    Enable-PSRemoting -Force
    Write-Output "`n"
}

# We will test the connection to the DC now.
if (!(Test-WSMan $DCName)) {
    Write-Output 'Unable to connect to DC...'
    exit
}

# We will retrieve the user name.
$AdmUsr = $env:USERNAME

# Time to connect to the DC.
Enter-PSSession -ComputerName $SSDC -Credential $AdmUsr
Write-Output 'In the process of connecting to the DC...'
Write-Output "`n"

# We will retrieve the user input now.
$FirstName = Read-Host -Prompt 'Enter the first name:'
$LastName = Read-Host -Prompt 'Enter the last name:'
$Email_Adx = Read-Host -Prompt 'Enter the user email address:'

# Time to construct the new user account.
$DisplayName = $FirstName + '.' + $LastName
Write-Output "`n"
Write-Output 'New user display name is: ' $DisplayName

# Time to generate a random password.
$GenPass = [System.Web.Security.Membership]::GeneratePassword(8, 0)

# Time to convert the password to a SecureString.
$SecurePass = ConvertTo-SecureString -String $GenPass -AsPlainText -Force
Write-Output "`n"
Write-Output 'New user password is: ' $GenPass

# Using "New-ADUser" to create the user.
New-ADUser -UserPrincipalName $DisplayName -Name $DisplayName -AccountPassword $SecurePassword -ChangePasswordAtLogon 1 -DisplayName $DisplayName -EmailAddress $Email -Enabled 1 -GivenName $FirstName -Surname $LastName -Path 'DC=server,DC=com' # Replace 'DC=server,DC=com" with the true domain info. (JEA_20230621)
Write-Output "`n"
Write-Output 'The new user was created.'

# End PS Session now.
Exit-PSSession

# Send a notification.
Write-Output "Sending an email notification now`n"
$Subject = 'Windows User information'
$Body = 'The following information was created for ' + $FirstName + '' + $LastName + "`n"
$Body += "`tUser Email       : " + $Email + "`n"
$Body += "`tWindows Logon    : " + $DisplayName + "`n"
$Body += "`tWindows Password : " + $Password + "`n"

$ITAdm = 'ITADM@domain.com' # Replace this with your domain email.

# Sending the notification via SMTP.
$SMTP_User = Read-Host -Prompt 'Enter your SMTP User.'
$SMTP_Pass = Read-Host -Prompt 'Enter your SMTP Password.'
$SMTP_Server = 'mail.domain.com' # Replace this with your email server info.
$SMTP_Port = $SMTP_Port_Num

function STE([string]$mailUser) {
    $message = New-Object Net.Mail.MailMessage;
    $message.From = $ITAdm;
    $message.CC.Add($ITAdm);
    $message.To.Add($Email_Adx);
    $message.Subject = $Subject;
    $message.Body = $Body;
    $smtp = New-Object Net.Mail.SmtpClient($SMTP_Server, $SMTP_Port);
    $smtp.EnableSSL = $true;
    $smtp.Credentials = New-Object System.Net.NetworkCredential($SMTP_User, $SMTP_Pass);
    $smtp.send($message);
    Write-Host 'Notification Sent' ;
}

Send-ToEmail($Email)

# Goodbye...
Read-Host -Prompt 'Press Enter to exit.'