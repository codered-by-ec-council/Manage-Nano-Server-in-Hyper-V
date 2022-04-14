CLS
$HV_NODE="HV02"
Invoke-Command -ComputerName $HV_NODE -ScriptBlock{

    # Define Settings
    $VM_NAME        = "VM02"
    $VM_MEM         = 512
    $VMS_PATH       = "C:\VMs"
    $VMS_PROCESSORS = 2 
    $VMS_GENERATION = 1
    $VMS_SWITCH     = "PRIVATE"

    # Check IF VM already exists
    IF(!( Get-VM -Name $VM_NAME -ErrorAction SilentlyContinue)){

        # Create VM Switch
        IF(!( Get-VMSwitch -Name $VMS_SWITCH -ErrorAction SilentlyContinue )){ New-VMSwitch -Name $VMS_SWITCH -SwitchType Private }

        # Convert memory from MB to Bytes
        $VM_MEM_START = [int64]$VM_MEM * 1024 * 1024

        # Create VMs path direcotry
        IF(!(Test-Path -Path $VMS_PATH)){ New-Item -ItemType Directory -Path $VMS_PATH }

        # Create VMs without VHD
        New-VM -Name $VM_NAME `
            -MemoryStartupBytes ${VM_MEM_START} `
            -Path $VMS_PATH `
            -Generation $VMS_GENERATION `
            -NoVHD

        # Set VM Processors
        Set-VMProcessor -VMName $VM_NAME -Count $VMS_PROCESSORS

        # Set VM Settings
        Set-VM -Name $VM_NAME `
            -AutomaticStartAction Nothing `
            -AutomaticStopAction ShutDown

        # Set VM boot order
        Set-VMBios -VMName $VM_NAME -StartupOrder @("IDE", "Floppy", "LegacyNetworkAdapter", "CD")

        # Remove DVD Drive
        Remove-VMDvdDrive -VMName $VM_NAME -ControllerNumber 1 -ControllerLocation 0

        # Create Virtual Hard Disks directory
        IF(!(Test-Path -Path "C:\VMs\${VM_NAME}\Virtual Hard Disks")){ New-Item -ItemType Directory -Path "C:\VMs\${VM_NAME}\Virtual Hard Disks" }

        # Connect to VSwitch
        Connect-VMNetworkAdapter -VMName $VM_NAME -SwitchName $VMS_SWITCH
        
        Write-Host "VM $VM_NAME has been created" -ForegroundColor Green
    }
    ELSE{
        Write-Host "VM $VM_NAME already exists" -ForegroundColor Red
    }
}
