# VMs Creation 

# Clear the screen
cls

# Default settings
$VMS_PATH       = "C:\VMs" # Directory where VMs are hosted
$VMS_GENERATION = 1 # Generation of VM
$VMS_PROCESSORS = 2 # Number of vProcessors to be associated on each VM
$VMS_SWITCH     = "PRIVATE" # Name of vSwitch to connect the VMs

# Declare VMs to be created
$VMs = @()
$VMsCounter ++

# Domain Controller
$VMs += ,@($VMsCounter, 'ECCOUNCIL_DC01','no','dyn',1024,3072)
$VMsCounter ++

# Hyper-V 01 Nano Server node
$VMs += ,@($VMsCounter, 'ECCOUNCIL_HV01','yes','stat',2048)
$VMsCounter ++

# Hyper-V 02 Nano Server node
$VMs += ,@($VMsCounter, 'ECCOUNCIL_HV02','yes','sta',2048)
$VMsCounter ++

# SCVMM node
$VMs += ,@($VMsCounter, 'ECCOUNCIL_SCVMM','no','dyn',1024,4096)
$VMsCounter ++

# Start the creation of VMs
foreach($VM in $VMs){

    # Populate VM Variable
    $VM_NAME      = $VM[1] # Set the name of VM
    $VM_NESTED    = $VM[2] # Set nested virtualization
    $VM_MEM_TYPE  = $VM[3] # Set memory as dynamic or static
    $VM_MEM_START = [int64]$VM[4] * 1024 * 1024 # Set start memory for dynamic or fixed
    $VM_MEM_LIMIT = [int64]$VM[5] * 1024 * 1024 # Set limit of the memory (Only for dynamic)

    # Create the VM if not exists
    IF(!(Get-VM -Name $VM_NAME -ErrorAction SilentlyContinue)){
 
        # Create VMs without VHD
        New-VM -Name $VM_NAME `
            -MemoryStartupBytes ${VM_MEM_START} `
            -Path $VMS_PATH `
            -Generation $VMS_GENERATION `
            -NoVHD

        # Set VM Processors
        Set-VMProcessor -VMName $VM_NAME -Count $VMS_PROCESSORS

        # Set nested virtualization
        IF($VM_NESTED){
            Set-VMProcessor -VMName $VM_NAME -ExposeVirtualizationExtensions $true   
        }

        # Set the dynamic memory
        IF($VM_MEM_TYPE -eq "dyn"){
            Set-VM -Name $VM_NAME -DynamicMemory -MemoryMaximumBytes $VM_MEM_LIMIT
        }

        # Set VM Settings
        Set-VM -Name $VM_NAME `
            -AutomaticStartAction Nothing `
            -AutomaticStopAction ShutDown

        # Set VM boot order
        Set-VMBios -VMName $VM_NAME -StartupOrder @("IDE", "Floppy", "LegacyNetworkAdapter", "CD")

        # Remove DVD Drive
        Remove-VMDvdDrive -VMName $VM_NAME -ControllerNumber 1 -ControllerLocation 0

        # Create Virtual Hard Disks directory
        New-Item -ItemType Directory -Path "C:\VMs\${VM_NAME}\Virtual Hard Disks"

        # Connect to VSwitch
        Connect-VMNetworkAdapter -VMName $VM_NAME -SwitchName $VMS_SWITCH

        Write-Host "VM $VM_NAME has been created" -ForegroundColor Green
    }
    ELSE{
        Write-Host "VM $VM_NAME already exists" -ForegroundColor Yellow
    }
}