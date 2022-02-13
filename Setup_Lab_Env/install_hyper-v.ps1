# Set settings variables
$VMS_PATH="C:"
$VMS_DIR="${VM_PATH}/VMs"
$VHD_PATH="${VMS_PATH}/${VMS_DIR}/Virtual Hard Disks/"
$VM_SWITCH="PRIVATE"

# Install Hyper-V role and required features for management (Restart may be required)
IF(!(Get-WindowsFeature -Name Hyper-V)){
    Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
}

# Create VMs directory
IF(!(Test-Path ${VMS_DIR} )){
    New-Item -ItemType Directory -Path $VMS_PATH -Name $VMS_DIR
}

# Set Default VMs Path
Set-VMHost -VirtualMachinePath ${VMS_DIR}

# Set Default Virtual Hard Disks Path
Set-VMHost -VirtualHardDiskPath $VHD_PATH

# Create the VM Switch
New-VMSwitch -Name $VM_SWITCH -SwitchType Private 

<# 
References:
- https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/install-the-hyper-v-role-on-windows-server
#>