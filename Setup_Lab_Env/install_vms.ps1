# VMs Creation 

# Default settings
$VMS_PATH       = "C:\VMs"
$VMS_GENERATION = 2
$VMS_PROCESSORS = 2

# Declare VMs to be created
$VMs = @()
$VMsCounter ++

# Domain Controller
$VMs += ,@($VMsCounter, 'DC01',50,'dyn',1024,3072)
$VMsCounter ++

# Hyper-V 01 Nano Server node
$VMs += ,@($VMsCounter, 'HV01',0,'stat',2048)
$VMsCounter ++

# Hyper-V 02 Nano Server node
$VMs += ,@($VMsCounter, 'HV02',0,'sta',2048)
$VMsCounter ++

# Start the creation of VMs
foreach($VM in $VMs){
    # Populate VM Variable
    $VM_NAME      = $VM[1]
    $VM_VHD_SIZE  = [int64]$VM[2] * 1024 * 1024 * 1024
    $VM_MEM_TYPE  = $VM[3]
    $VM_MEM_START = [int64]$VM[4] * 1024 * 1024

    # Create the VM if not exists
    IF(!(Get-VM -Name $VM_NAME -ErrorAction SilentlyContinue)){
 
        # Create VM with VHD
        IF($VM_VHD_SIZE -ne 0){
            New-VM -Name $VM_NAME `
                -MemoryStartupBytes ${VM_MEM_START} `
                -Path $VMS_PATH `
                -Generation $VMS_GENERATION `
                -NewVHDPath "${VMS_PATH}/${VM_NAME}/Virtual Hard Disks/${VM_NAME}_OS.vhdx" `
                -NewVHDSizeBytes $VM_VHD_SIZE
            Pause
        }
    
        # Create VM without VHD
        IF($VM_VHD_SIZE -eq 0){
            New-VM -Name $VM_NAME `
                -MemoryStartupBytes ${VM_MEM_START} `
                -Path $VMS_PATH `
                -Generation $VMS_GENERATION `
                -NoVHD
            Pause
        }
    }
}