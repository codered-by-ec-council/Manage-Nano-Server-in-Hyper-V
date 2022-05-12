# Declare variables
$SCVMM_INSTALL_FILE = "C:\Users\eccouncil\Downloads\SCVMM\SC2016_SCVMM_VHD.exe" # Path of the file that contains VHD
$VM_NAME            = "ECCOUNCIL_SCVMM" # Name of SCVMM VM
$VMs_PATH           = "C:\VMs" # Path to host VMs
$VM_USER            = "Administrator" # Username for authentication
$VM_PASSWORD        = "P@ssw0rd" # Password for authentication
$VM_HOSTNAME        = "SCVMM01" # Hostname to be set on VM
$VM_IP_ADDR         = "10.0.0.40" # IP Address of DC
$VM_IP_PREFIX       = "24" # Subnet to be set on interface
$DOMAIN_NAME        = "eccouncil.local" # Domain that will be created
$DNS_SERVER         = "10.0.0.10" # DNS Server IP Address

Function checks(){
    # Check SCVMM install path file
    $GLOBAL:CHECK_SCVMM_INSTALL_FILE=Test-Path -Path $SCVMM_INSTALL_FILE -ErrorAction SilentlyContinue

    # Check if VM exists
    $GLOBAL:CHECK_VM_EXISTS=Get-VM -Name $VM_NAME -ErrorAction SilentlyContinue

    # Check if VHD exists
    $GLOBAL:CHECK_VHD_EXISTS=Test-Path -Path "${VMs_PATH}\${VM_NAME}\Virtual Hard Disks\${VM_NAME}_OS.vhd" -ErrorAction SilentlyContinue
}

Function create_VHD(){
    IF(!($CHECK_VHD_EXISTS)){
        # Extract the VHD
        Start-Process `
            -FilePath $SCVMM_INSTALL_FILE `
            -ArgumentList "/SILENT /DIR=`"${VMs_PATH}\${VM_NAME}\Virtual Hard Disks`"" `
            -Wait `
            -PassThru

        # Rename the VHD
        Rename-Item `
            -Path "${VMs_PATH}\${VM_NAME}\Virtual Hard Disks\SCVMM_EVAL_FINAL.vhd" `
            -NewName "${VMs_PATH}\${VM_NAME}\Virtual Hard Disks\${VM_NAME}_OS.vhd"
    }
}

Function attach_VHD(){
    IF(!(Get-VMHardDiskDrive -VMName $VM_NAME -ControllerLocation 0 -ControllerNumber 0 -ErrorAction SilentlyContinue)){
        # Stop VM if required
        stop_VM

        # Attach VHD to VM
        Write-Host "VHD file ${VMs_PATH}\${VM_NAME}\Virtual Hard Disks\${VM_NAME}_OS.vhd was added" -ForegroundColor Yellow
        Add-VMHardDiskDrive -VMName $VM_NAME `
            -Path "${VMs_PATH}\${VM_NAME}\Virtual Hard Disks\${VM_NAME}_OS.vhd" `
            -ControllerType IDE `
            -ControllerNumber 0 `
            -ControllerLocation 0

        # Start VM
        start_VM

        # Ask for confirmation to continue
        $Shell = New-Object -ComObject "WScript.Shell"
        $Button = $Shell.Popup("Please complete the installation and then set the Administrator password to $VM_PASSWORD", 0, "Continue installation", 0)
    }
}

Function start_VM(){
    # Start the VM
    IF($CHECK_VM_EXISTS){ 
        IF( $CHECK_VM_EXISTS.State -eq "off" ){
            Write-Host "Starting the VM $VM_NAME" -ForegroundColor Yellow
            Start-VM -Name $VM_NAME
        }
    }
}

Function stop_VM(){
    # Stop the VM
    IF($CHECK_VM_EXISTS){ 
        IF( $CHECK_VM_EXISTS.State -eq "Running" ){
            Write-Host "Stoping the VM $VM_NAME" -ForegroundColor Yellow
            Stop-VM -Name $VM_NAME
        }
    }
}

Function setup_VM(){
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
            $DOMAIN_NAME, $VM_PASSWORD_SEC, $DNS_SERVER, $VM_USER `
            -Credential $CRED `
            -ScriptBlock{
        
            # Set Variables by arguments
            $VM_NAME         = $args[0]
            $VM_IP_ADDR      = $args[1]
            $VM_IP_PREFIX    = $args[2]
            $DOMAIN_NAME     = $args[3]
            $VM_PASSWORD_SEC = $args[4]
            $DNS_SERVER      = $args[5]
            $VM_USER         = $args[6]
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
            Set-DnsClientServerAddress -InterfaceIndex $VM_INT_INDEX -ServerAddresses $DNS_SERVER
            Write-Host "DNS server was set to $DNS_SERVER" -ForegroundColor Yellow
        
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

            # Install Failover Clustering Feature
            IF( (Get-WindowsFeature -Name RSAT-Clustering).InstallState -eq "Available"){
                Install-WindowsFeature -Name RSAT-Clustering
            }

            # Install ADDS Feature
            IF( (Get-WindowsFeature -Name RSAT-ADDS).InstallState -eq "Available"){
                Install-WindowsFeature -Name RSAT-ADDS
            }

            # Install Hyper-V RSAT
            IF( (Get-WindowsFeature -Name RSAT-Hyper-V-Tools).InstallState -eq "Available"){
                Install-WindowsFeature -Name RSAT-Hyper-V-Tools
            }

            # Install File Services Role
            IF( (Get-WindowsFeature -Name File-Services).InstallState -eq "Available"){
                Install-WindowsFeature -Name File-Services
            }
            
            # Join on Domain
            IF( !( (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain )){
                Write-Host "Joining VM $VM_NAME on domain $DOMAIN_NAME" -ForegroundColor Yellow 
                $Creds = New-Object System.Management.Automation.PSCredential($VM_USER,$VM_PASSWORD_SEC)
                Add-Computer -DomainName $DOMAIN_NAME -Credential $Creds -Restart
            }
        }
    }
}


# Start the checks
cls
checks
create_VHD
attach_VHD
setup_VM
