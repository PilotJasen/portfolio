###########################
# NAME: Change AD Pass    #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/20     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# This purpose of this script is to update the AD password for a specified user.
# It is best to "Run-as Administrator" for this script.

# PowerShell variables
$usr_prompt = 'Enter the username to change the password.' # We will give the user we want to change the password for.
$password_change = 'Enter the new password.' # We will give it the new password to change it for the user.
$password_prompt = 'Do you know the current password? (Y/N)' # Do we know the current user account password?
$old_pass_prompt = 'Enter the current password' # We will enter the current password.
$adm_cred = 'Please enter the domain admin credentials.' # We will enter the domain admin credentials.

# Importing the AD module.
Import-Module ActiveDirectory
$usrName = Read-Host -Prompt "$usr_prompt"
$new_pass = Read-Host -Prompt "$password_change" -AsSecureString

# Time to get the user info.
$usrDn = (Get-ADUser -Identity $usrName).DistinguishedName
do {
    $pass_known = Read-Host -Prompt "$password_prompt"
} until ($pass_known -match '[yY|nN|yesYes|noNo]')

if ($pass_known -eq 'Y') {
    $old_pass = Read-Host "$old_pass_prompt" -AsSecureString
    Set-ADAccountPassword -Identity $usrDn -OldPassword $old_pass -NewPassword $new_pass
}
else {
    $get_adm_cred = Get-Credential -Message "$adm_cred"
    Set-ADAccountPassword -Identity $usrDn -NewPassword $new_pass -Reset -Credential $get_adm_cred
}