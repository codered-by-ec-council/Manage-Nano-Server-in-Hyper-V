# Domain Controller setup

# Clear the screen
cls

# Domain Controller settings
$VM_NAME      = "ECCOUNCIL_DC01" # Name of VM to install DC role
$VM_HOSTNAME  = "DC01" # Hostname to be set on VM
$VM_IP_ADDR   = "10.0.0.10" # IP Address of DC
$VM_IP_PREFIX = "24" # Subnet to be set on interface
$DOMAIN_NAME  = "eccouncil.local" # Domain that will be created 
$VMS_PATH     = "C:\VMs" # Directory where VMs are hosted
$VHD_TEMPLATE = "$env:HOMEPATH\Downloads\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" # Template VHD file
$VM_USER      = "Administrator" # Username for authentication
$VM_PASSWORD  = "P@ssw0rd" # Password for authentication

# DHCP Scope Settings
$DHCP_SCOPE_NAME   = "eccouncil"
$DHCP_SCOPE_START  = "10.0.0.100"
$DHCP_SCOPE_END    = "10.0.0.200"
$DHCP_SCOPE_SUBNET = "255.255.255.0"

# Check if VHD template file exists
IF(!(Test-Path $VHD_TEMPLATE)){
    Write-Host "VHD file $VHD_TEMPLATE was not found, please check" -ForegroundColor Red
    exit 1
}

# Copy VHD template file
IF(!(Test-Path -Path "${VMS_PATH}\${VM_NAME}\Virtual Hard Disks\${VM_NAME}_OS.vhd")){
    Write-Host "Copying VHD template file, please wait" -ForegroundColor Yellow
    Copy-Item -Path $VHD_TEMPLATE -Destination "${VMS_PATH}\${VM_NAME}\Virtual Hard Disks\${VM_NAME}_OS.vhd"
}
ELSE{
    Write-Host "VHD file ${VMS_PATH}\${VM_NAME}\Virtual Hard Disks\${VM_NAME}_OS.vhd already exists." -ForegroundColor Green
}

# Attach VHD to VM
IF(!(Get-VMHardDiskDrive -VMName $VM_NAME -ControllerLocation 0 -ControllerNumber 0 -ErrorAction SilentlyContinue)){
    Write-Host "VHD file ${VMS_PATH}\${VM_NAME}\Virtual Hard Disks\${VM_NAME}_OS.vhd was added" -ForegroundColor Yellow
    Add-VMHardDiskDrive -VMName $VM_NAME `
        -Path "${VMS_PATH}\${VM_NAME}\Virtual Hard Disks\${VM_NAME}_OS.vhd" `
        -ControllerType IDE `
        -ControllerNumber 0 `
        -ControllerLocation 0
}
ELSE{
    Write-Host "IDE Controller is already allocated, please check the VHD." -ForegroundColor Green
}

# Start the VM
IF($VM_STATUS=(Get-VM -VMName $VM_NAME).State -eq "off"){
    Write-Host "Starting the VM $VM_NAME, please wait." -ForegroundColor Yellow
    Start-VM -Name $VM_NAME
    $Shell = New-Object -ComObject "WScript.Shell"
    $Button = $Shell.Popup("Please complete the installation and then set the Administrator password to $VM_PASSWORD", 0, "Continue DC installation", 0)    
}
ELSE{
    Write-Host "VM $VM_NAME is already started" -ForegroundColor Green
}

# Create authentication
$VM_PASSWORD_SEC = ConvertTo-SecureString -String $VM_PASSWORD -AsPlainText -Force
$CRED = new-object -typename System.Management.Automation.PSCredential -argumentlist $VM_USER, $VM_PASSWORD_SEC

# Check connectivity 
$error.clear()
try{ Invoke-Command -VMName $VM_NAME -Credential $CRED -ScriptBlock{ Write-Host "Connection established to $env:COMPUTERNAME" -ForegroundColor Yellow } -ErrorAction SilentlyContinue }
catch {"Connection error to $VM_NAME"}
IF(!$error) {
    # Run commands direct on VM
    Invoke-Command -VMName $VM_NAME -ArgumentList `
      $VM_HOSTNAME, $VM_IP_ADDR, $VM_IP_PREFIX, `
      $DOMAIN_NAME, $VM_PASSWORD_SEC, `
      $DHCP_SCOPE_NAME, $DHCP_SCOPE_START, $DHCP_SCOPE_END, $DHCP_SCOPE_SUBNET `
      -Credential $CRED `
      -ScriptBlock{
        
        # Set Variables by arguments
        $VM_NAME           = $args[0]
        $VM_IP_ADDR        = $args[1]
        $VM_IP_PREFIX      = $args[2]
        $DOMAIN_NAME       = $args[3]
        $VM_PASSWORD_SEC   = $args[4]
        $DHCP_SCOPE_NAME   = $args[5]
        $DHCP_SCOPE_START  = $args[6]
        $DHCP_SCOPE_END    = $args[7]
        $DHCP_SCOPE_SUBNET = $args[8]
        $VM_INT          = "Ethernet"
        $VM_INT_INDEX    = (Get-NetAdapter -Name $VM_INT).ifIndex
        
        # Set IP address
        IF( ((Get-NetIPConfiguration -InterfaceIndex $VM_INT_INDEX).IPv4Address).IPAddress -ne $VM_IP_ADDR ){
            Remove-NetIPAddress -InterfaceIndex $VM_INT_INDEX -Confirm:$false
            New-NetIPAddress -IPAddress $VM_IP_ADDR -InterfaceIndex $VM_INT_INDEX -AddressFamily IPv4 -PrefixLength $VM_IP_PREFIX
            Write-Host "IP Address was set to ${VM_IP_ADDR}/24" -ForegroundColor Yellow
        }
        ELSE{
            Write-Host "IP Address ${VM_IP_ADDR}/24 is already set" -ForegroundColor Green
        }

        # Set DNS address
        Set-DnsClientServerAddress -InterfaceIndex $VM_INT_INDEX -ServerAddresses $VM_IP_ADDR
        Write-Host "DNS server was set to $VM_IP_ADDR" -ForegroundColor Yellow

        # Install ADDS Roles and Features
        IF( (Get-WindowsFeature -Name AD-Domain-Services).InstallState -eq "Available" ){
            Write-Host "Installing ADDS Roles and Features, please wait" -ForegroundColor Yellow
            Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
        }
        ELSE{
            Write-Host "ADDS Role is already installed" -ForegroundColor Green
        }
       
        # Install Hyper-V Feature
        IF( (Get-WindowsFeature -Name RSAT-Hyper-V-Tools).InstallState -ne "Installed" ){
        Write-Host "Installing Hyper-V feature on $VM_NAME to manage Nano Server, please wait" -ForegroundColor Yellow
        Install-WindowsFeature -Name RSAT-Hyper-V-Tools
        }
        ELSE{
        Write-Host "Hyper-V feature is already installed on $VM_NAME" -ForegroundColor Green
        }

        # Setup DHCP Server
        IF( (Get-WindowsFeature -Name 'DHCP').InstallState -ne "Installed" ){
            
            # Install DHCP Server
            Write-Host "Installing DHCP Role and Feature, please wait" -ForegroundColor Yellow
            Install-WindowsFeature -Name 'DHCP' -IncludeManagementTools
            
            # Setup DHCP Scope
            Add-DhcpServerV4Scope `
              -Name $DHCP_SCOPE_NAME `
              -StartRange $DHCP_SCOPE_START `
              -EndRange $DHCP_SCOPE_END `
              -SubnetMask $DHCP_SCOPE_SUBNET
            
            # Add DNS Server Scope Option
            Set-DhcpServerv4OptionValue `
              -ScopeId ((Get-DhcpServerv4Scope | Where-Object{$_.Name -eq $DHCP_SCOPE_NAME}).ScopeId).IPAddressToString `
              -DnsServer $VM_IP_ADDR -Force
        }
        ELSE{
            Write-Host "DHCP Server Role is already installed" -ForegroundColor Green
        }

        # Rename the VM
        IF($env:COMPUTERNAME -ne $VM_NAME){
            Rename-Computer -NewName $VM_NAME -Force
            Write-Host "Computer was renamed to $VM_NAME" -ForegroundColor Yellow
            Write-Host "Computer will be restarted, please run the script again to continue" -ForegroundColor Yellow
            Restart-Computer -Force
            break
        }
        ELSE{
            Write-Host "Computer name is already set to $VM_NAME" -ForegroundColor Green
        }
        
        # Promote to DC
        $error.clear()
        try{ Get-ADForest -Identity $DOMAIN_NAME }
        catch {}
        IF($error){
            Write-Host "Installing the forest $DOMAIN_NAME, please wait." -ForegroundColor Yellow
            Install-ADDSForest `
                -DomainName $DOMAIN_NAME `
                -DomainMode Win2012R2 `
                -ForestMode Win2012R2 `
                -DatabasePath "C:\ADDS\NTDS" `
                -SysvolPath "C:\ADDS\SYSVOL" `
                -LogPath "C:\ADDS\Logs" `
                -SafeModeAdministratorPassword $VM_PASSWORD_SEC `
                -Confirm:$false

            Write-Host "Installation has been completed, the VM $VM_NAME is expect to restart, and then domain is ready" -ForegroundColor Green                        
        }
        ELSE{
            Write-Host "The forest $DOMAIN_NAME is already installed." -ForegroundColor Green
        }        
    }
}
ELSE{
    Write-Host "Connection to $VM_NAME has failed, probably ADDS forest $DOMAIN_NAME is already set, please check" -ForegroundColor Red
}