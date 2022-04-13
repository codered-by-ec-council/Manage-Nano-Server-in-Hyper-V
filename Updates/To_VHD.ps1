# Define Settings
$VDH_PATH     = "C:\VMs\ECCOUNCIL_HV02\Virtual Hard Disks\ECCOUNCIL_HV02_OS.vhd"
$MOUNT_PATH   = "C:\MountImages"
$UPDATES_PATH = "C:\Updates"

CLS

IF(Test-Path -Path $VDH_PATH){
    # Create Mount directory
    IF(!(Test-Path -Path $MOUNT_PATH)){New-Item -ItemType Directory -Path $MOUNT_PATH}

    # Check if image is mounted already
    IF(!(Get-WindowsImage -Mounted)){        
        Write-Host "Mouting the VHD file $VHD_PATH on $MOUNT_PATH, please wait" -ForegroundColor Yellow
        Mount-WindowsImage -ImagePath $VDH_PATH -Path $MOUNT_PATH -Index 1
        
        Write-Host "Installing the updates of the folder $UPDATE_PATH, please wait" -ForegroundColor Yellow
        Add-WindowsPackage -Path $MOUNT_PATH -PackagePath ${UPDATES_PATH}
        
        Write-Host "Unmount the image $IMAGE_MOUNTED from $MOUNT_PATH" -ForegroundColor Yellow
        Dismount-WindowsImage -Path $MOUNT_PATH -Save
    }
    ELSE{
        $IMAGE_MOUNTED=(Get-WindowsImage -Mounted).ImagePath
        $IMAGE_MOUNTED
        Write-Host "The image $IMAGE_MOUNTED is already mounted on $MOUNT_PATH, please check" -ForegroundColor Red
    }
}
ELSE{
    Write-Host "VHD file $VHD_PATH does not exists, please check" -ForegroundColor Red
}