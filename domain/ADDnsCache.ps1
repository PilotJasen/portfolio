###########################
# NAME: ADDnsCache Flush  #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/20     #
# (C) 2022-2023           #
###########################

# Run "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned".

# We will gather all DC in the domain to flush their DNS caches one at a time.
Get-ADDomainController -Filter * | ForEach-Object { Clear-DnsServerCache -ComputerName $_.HostName -Force }