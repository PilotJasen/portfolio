###########################
# NAME: Remove DHCP OPS   #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/20     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# The purpose of this script is to remove DHCP options.

# PowerShell variables.
$DhcpSvrOptRm = 'Deleting DHCP server option.'
$DhcpScopeRm = 'Removing DHCP server scope.'

# Time to connect to the DHCP Server.
Import-Module DhcpServer

# Specify what server to connect to.
$DhcpServers = @('', '')

# Specify what option you want to remove.
$DhcpOptRem = @('', '')

# We will cycle through each DHCP Server.
foreach ($DhcpServer in $DhcpServers) {
    # Retrieve the options list from the server.
    $SvrOpts = Get-DhcpServerv4OptionValue -ComputerName $DhcpServer

    # Retrieve the DHCP scopes.
    $DhcpServerScope = Get-DhcpServerv4Scope -ComputerName $DhcpServer

    # Cycle through the options that will need to be removed.
    foreach ($OptToRm in $SvrOpts.OptionId) {
        Write-Output -InputObject ("'$DhcpSvrOptRm'" + $OptToRm + 'from' + $DhcpServer + '.')
        Remove-DhcpServerv4OptionValue -ComputerName $DhcpServer -OptionId $OptToRm
    }
    # Cycle through DHCP scopes.
    foreach ($DhcpServerScope in $DhcpServerScopes) {
        # Retrieve the DHCP scope.
        $ScopeOpt = Get-DhcpServerv4OptionValue -ComputerName $DhcpServer -ScopeId $DhcpServerScope.ScopeId

        # If we locate the option, then we will remove it.
        if ($OptToRm -in $ScopeOpt.OptionId) {
            Write-Output -InputObject ("'$DhcpScopeRm'" + $OptToRm + 'from' + $DhcpServerScope.ScopeId + 'on' + $DhcpServer + '.')
            Remove-DhcpServerv4OptionValue -ComputerName $DhcpServer -ScopeId $DhcpServerScope.ScopeId -OptionId $OptToRm
        }
    }
}