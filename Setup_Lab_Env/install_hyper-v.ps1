# Install Hyper-V

# Clear the screen
cls

# Set settings variables
$VMS_PATH="C:"
$VMS_DIR="${VM_PATH}/VMs"
$VHD_PATH="${VMS_PATH}/${VMS_DIR}/Virtual Hard Disks/"
$VMS_SWITCH="PRIVATE"

# Install Hyper-V role and required features for management (Restart may be required)
IF(!( (Get-WindowsFeature -Name Hyper-V).InstallState -ne "Available" )){
    Write-Host "Installing Hyper-V feature, please wait" -ForegroundColor Yellow
    Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
}
ELSE{
    Write-Host "The Hyper-V feature is already installed" -ForegroundColor Blue
}

# Continue only if commands are available
IF(Get-Command -Name Get-vmhost -ErrorAction SilentlyContinue){
    # Create VMs directory
    IF(!(Test-Path ${VMS_DIR} )){
        New-Item -ItemType Directory -Path $VMS_PATH -Name $VMS_DIR
    }

    # Set Default VMs Path
    Set-VMHost -VirtualMachinePath ${VMS_DIR}

    # Set Default Virtual Hard Disks Path
    Set-VMHost -VirtualHardDiskPath $VHD_PATH

    # Create the VM Switch
    IF(! (Get-VMSwitch -Name $VMS_SWITCH -ErrorAction SilentlyContinue) ){
        Write-Host "Creating the VSwitch $VMS_SWITCH" -ForegroundColor Yellow
        New-VMSwitch -Name $VMS_SWITCH -SwitchType Private 
    }
    ELSE{
        Write-Host "The vSwitch $VMS_SWITCH already exists" -ForegroundColor Blue
    }

    # Enable Enhanced Session
    Set-VMHost -EnableEnhancedSessionMode $true
}