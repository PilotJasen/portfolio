#######################
# NAME: Network Utils #
# AUTHOR: DesertRatz  #
# CREATED: 2025/05/07 #
# (C) 2024-2026       #
#######################

<#
.SYNOPSIS
    Network Utility Tool with GUI

.DESCRIPTION
    This script / GUI will do the following: Clear DNS Cache, Renews IP on active interface, and updates group policies.

.NOTES
    version: 1.0
#>

# Custom PowerShell var
$PS_Net_Maintenance = "Perform network maintenance tasks with a single click"

# PowerShell DHCP message(s)
$PS_DHCP_Retrieve = "Getting active network adapters..."
$PS_DHCP_Active = "Found active adapter: $($activeAdapter.Name)"
$PS_DHCP_Active_None = "No active network adapter found. Please check your network connection."
$PS_DHCP_Active_None_Skip = "No active network adapter found. Skipping IP renewal."
$PS_DHCP_Renew = "Renewing IP address on $($activeAdapter.Name)..."
$PS_DHCP_Renew_Success = "IP address renewed successfully."
$PS_DHCP_Renew_Failed = "Failed to renew IP address"
$PS_DHCP_Renew_Error = "Error renewing IP address: $($_.Exception.Message)"
$PS_DHCP_Renew_New = "New IP Configuration:"
$PS_DHCP_Renew_Unable = "Unable to retrieve IP configuration"
$PS_DHCP_Renew_Name = "Renew IP"

# PowerShell DNS message(s)
$PS_ClearDNS_Title = "Flush DNS Cache"
$PS_ClearDNS_Failed = "Failed to flush DNS cache"
$PS_ClearDNS_Start = "Starting DNS cache flush..."
$PS_ClearDNS_Success = "DNS cache successfully flushed"
$PS_ClearDNS_Status = "DNS cache status:"
$PS_ClearDNS_Unable = "Unable to display DNS cache"

# PowerShell Group Policy message(s)
$PS_GPO_Update = "Group Policy Update"
$PS_GPO_Success = "Group Policy update completed successfully"
$PS_GPO_Failed = "Failed to update Group Policy"
$PS_GP_Update = "Updating Group Policy..."

# PowerShell Run All message(s)
$PS_Run_All = "Run All Operations"
$PS_Run_All_Net = "Running all network operations..."
$PS_Run_DNS_Flush = "STEP 1/3: Flushing DNS cache..."
$PS_Run_IP_Renew = "STEP 2/3: Renewing IP address..."
$PS_Run_GP_Update = "STEP 3/3: Updating Group Policy..."

# PowerShell app message(s)
$PS_App_Name = "Network Utility Tool"

# PowerShell app operation status
$PS_App_Status = "All operations completed"

# PowerShell colors var
$PS_Colors_Black = "Black"
$PS_Colors_Blue = "Blue"
$PS_Colors_Green = "Green"
$PS_Colors_Red = "Red"
$PS_Color_Purple = "Purple"

# PowerShell date/time format var
$PS_dt_Format = "yyyy-MM-dd HH:mm:ss"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "$PS_App_Name"
$form.Size = New-Object System.Drawing.Size(550, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

# Create a title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 30)
$titleLabel.Size = New-Object System.Drawing.Size(500, 30)
$titleLabel.Text = "$PS_App_Name"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::DarkBlue
$form.Controls.Add($titleLabel)

# Create a description label
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Location = New-Object System.Drawing.Point(20, 60)
$descLabel.Size = New-Object System.Drawing.Size(500, 40)
$descLabel.Text = "$PS_Net_Maintenance"
$descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($descLabel)

# Create a status box for output
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 230)
$outputBox.Size = New-Object System.Drawing.Size(490, 200)
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::White
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($outputBox)

# Function to log messages to the output box
function Write-Log {
    param (
        [string]$Message,
        [string]$ForegroundColor = "$PS_Colors_Black"
    )
    $outputBox.SelectionColor = $ForegroundColor
    $timestamp = Get-Date -Format "$PS_dt_Format"
    $outputBox.AppendText("[$timestamp]$Message`r`n")
    $outputBox.ScrollToCaret()
}

# Function to execute commands and handle errors
function Start-Command {
    param (
        [scriptblock]$Command,
        [string]$SuccessMessage,
        [string]$ErrorMessage
    )
    try {
        $output = & $Command
        Write-Log $SuccessMessage -ForegroundColor "$PS_Colors_Green"
        if ($output) {
            $outputString = $output | Out-String
            Write-Log $outputString -ForegroundColor "$PS_Colors_Blue"
        }
        return $true
    }
    catch {
        Write-Log "$ErrorMessage`: $($_.Exception.Message)" -ForegroundColor "$PS_Colors_Red"
        return $false
    }
}

# Create DNS Flush button
$dnsButton = New-Object System.Windows.Forms.Button
$dnsButton.Location = New-Object System.Drawing.Point(20, 110)
$dnsButton.Size = New-Object System.Drawing.Size(150, 50)
$dnsButton.Text = "$PS_ClearDNS_Title"
$dnsButton.BackColor = [System.Drawing.Color]::LightBlue
$dnsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$dnsButton.Add_Click({
        Write-Log "$PS_ClearDNS_Start"
        $success = Start-Command -Command { Clear-DnsClientCache }` -SuccessMessage "$PS_ClearDNS_Success" -ErrorMessage "$PS_ClearDNS_Failed"
        if ($success) {
            Start-Command -Command { ipconfig /displaydns | Select-Object -First 5 }`
                -SuccessMessage "$PS_ClearDNS_Status"`
                -ErrorMessage "$PS_ClearDNS_Unable"
        }
    })
$form.Controls.Add($dnsButton)

# Create IP Renew button
$ipButton = New-Object System.Windows.Forms.Button
$ipButton.Location = New-Object System.Drawing.Point(180, 110)
$ipButton.Size = New-Object System.Drawing.Size(150, 50)
$ipButton.Text = "$PS_DHCP_Renew_Name"
$ipButton.BackColor = [System.Drawing.Color]::LightGreen
$ipButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ipButton.Add_Click({
        Write-Log "$PS_DHCP_Retrieve"

        try {
            # Retrieve the active network adapter that has an IP address and is connected to the network
            $activeAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue)
            } | Select-Object -First 1

            if ($activeAdapter) {
                Write-Log "$PS_DHCP_Active" -ForegroundColor Blue

                # Renew IP
                Write-Log "$PS_DHCP_Renew"
                $renewSuccess = Start-Command -Command {
                    ipconfig /renew "$($activeAdapter.interfaceAlias)"
                } -SuccessMessage "$PS_DHCP_Renew_Success" -ErrorMessage "$PS_DHCP_Renew_Failed"

                # Display the new IP configuration
                if ($renewSuccess) {
                    Start-Command -Command {
                        Get-NetIPAddress -InterfaceIndex $activeAdapter.ifIndex -AddressFamily IPv4 | Select-Object IPAddress, PrefixLength
                    } -SuccessMessage "$PS_DHCP_Renew_New" -ErrorMessage "$PS_DHCP_Renew_Unable"
                }
            }
            else {
                Write-Log "$PS_DHCP_Active_None" -ForegroundColor "$PS_Colors_Red"
            }
        }
        catch {
            Write-Log "$PS_DHCP_Renew_Error" -ForegroundColor "$PS_Colors_Red"
        }
    })
$form.Controls.Add($ipButton)

# Create Group Policy Update button
$gpButton = New-Object System.Windows.Forms.Button
$gpButton.Location = New-Object System.Drawing.Point(340, 110)
$gpButton.Size = New-Object System.Drawing.Size(150, 50)
$gpButton.Text = "$PS_GPO_Update"
$gpButton.BackColor = [System.Drawing.Color]::LightYellow
$gpButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$gpButton.Add_Click({
        Write-Log "$PS_GP_Update"
        Start-Command -Command { gpupdate /force } -SuccessMessage "$PS_GPO_Success" -ErrorMessage "$PS_GPO_Failed"
    })
$form.Controls.Add($gpButton)

# Create "Run All" button
$runAllButton = New-Object System.Windows.Forms.Button
$runAllButton.Location = New-Object System.Drawing.Point(180, 170)
$runAllButton.Size = New-Object System.Drawing.Size(150, 50)
$runAllButton.Text = "$PS_Run_All"
$runAllButton.BackColor = [System.Drawing.Color]::MistyRose
$runAllButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$runAllButton.Add_Click({

        # Time to call all three operations
        Write-Log "$PS_Run_All_Net" -ForegroundColor "$PS_Color_Purple"
    
        # DNS Flush
        Write-Log "$PS_Run_DNS_Flush"
        Start-Command -Command { Clear-DnsClientCache } -SuccessMessage "$PS_ClearDNS_Success" -ErrorMessage "$PS_ClearDNS_Failed"

        # IP Renew
        Write-Log "$PS_Run_IP_Renew"
        try {
            $activeAdapter = Get-NetAdapter | Where-Object {
                $_.Status -eq "Up" -and
                (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue)
            } | Select-Object -First 1

            if ($activeAdapter) {
                Write-Log "$PS_DHCP_Active" -ForegroundColor "$PS_Colors_Blue"
                Start-Command -Command {
                    ipconfig /renew "$($activeAdapter.interfaceAlias)"
                } -SuccessMessage "$PS_DHCP_Renew_Success" -ErrorMessage "$PS_DHCP_Renew_Failed"
            }
            else {
                Write-Log "$PS_DHCP_Active_None_Skip" -ForegroundColor "$PS_Colors_Yellow"
            }
        }
        catch {
            Write-Log "$PS_DHCP_Renew_Error" -ForegroundColor "$PS_Colors_Red"
        }

        # Group Policy Update
        Write-Log "$PS_Run_GP_Update"
        Start-Command -Command { gpupdate /force } -SuccessMessage "$PS_GPO_Success" -ErrorMessage "$PS_GPO_Failed"

        Write-Log "$PS_App_Status" -ForegroundColor "$PS_Colors_Green"
    })
$form.Controls.Add($runAllButton)

# Show the form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()