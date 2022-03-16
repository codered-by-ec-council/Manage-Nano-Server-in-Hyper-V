# Clear the screen
CLS

# Default variables
$DIR_PATH    = "C:\NanoImages"
$MEDIA_DRIVE = "E:"
$ADMIN_PWD   = "P@ssw0rd"
$DEPLOY_TYPE = "Guest"
$EDITION     = "Datacenter"
$NIC_DNS     = "10.0.0.10"
$NIC_SUBNET  = "255.255.255.0"
$NIC_INDEX   = "Ethernet"
$VMS_PATH    = "C:\VMs"
$DC_NAME     = "ECCOUNCIL_DC01"
$DC_USER     = "eccouncil\Administrator"
$BLOB_PATH   = "C:\DomJoin"
$DOMAIN_NAME = "eccouncil.local"

# Check if media is mounted
IF(Test-Path $MEDIA_DRIVE){

    # Import module
    Import-Module ${MEDIA_DRIVE}\NanoServer\NanoServerImageGenerator\NanoServerImageGenerator.psm1

    # Create Images directory
    IF(!(Test-Path -Path $DIR_PATH)){
        Write-Host "Creating the directory $DIR_PATH" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $DIR_PATH
    }
    ELSE{
        Write-Host "Directory $DIR_PATH already exists" -ForegroundColor Green
    }
    
    # Create blob path directory
    IF(!(Test-Path -Path ${BLOB_PATH})){
        New-Item -ItemType Directory -Path ${BLOB_PATH}
    }

    # Convert Admin password to secure
    $ADMIN_PWD_SEC = ConvertTo-SecureString -String $ADMIN_PWD -AsPlainText -Force

    # Declare NanoImages to be created
    $NIs = @()
    $NIsCounter ++

    # HV01
    $NIs += ,@($NIsCounter,'ECCOUNCIL_HV01','HV01',100GB,'10.0.0.20','hyperv')
    $NIsCounter ++

    # HV02
    $NIs += ,@($NIsCounter,'ECCOUNCIL_HV02','HV02',100GB,'10.0.0.30','hyperv')
    $NIsCounter ++

    # DNS01
    $NIs += ,@($NIsCounter,'ECCOUNCIL_DNS01','DNS01',100GB,'10.0.0.50','dns')
    $NIsCounter ++
        
    # IIS01
    $NIs += ,@($NIsCounter,'ECCOUNCIL_IIS01','IIS01',100GB,'10.0.0.70','iis')
    $NIsCounter ++      
        
    # Check if DC01 is ready
    IF($VM_STATUS=(Get-VM -VMName $DC_NAME).State -eq "off"){
        Write-Host "Starting the VM $DC_NAME, please wait." -ForegroundColor Yellow
        Start-VM -Name $DC_NAME
        Start-Sleep -Seconds 60
    }
    ELSE{
        Write-Host "VM $DC_NAME is already started" -ForegroundColor Green
    }
    
    # Start the creation of VMs
    foreach($NI in $NIs){
    
        # Populate Image Variable
        $NI_VM_NAME = $NI[1] # Set the name of VM
        $NI_NAME    = $NI[2] # Set the name of the image
        $NI_HD      = $NI[3] # Set the HD size of the image
        $NI_IP      = $NI[4] # Set the IP of the image        
        $NI_ROLE    = $NI[5] # Set the role of the image

        IF(!(Get-VMHardDiskDrive -VMName $NI_VM_NAME -ControllerLocation 0 -ControllerNumber 0 -ErrorAction SilentlyContinue)){            
                
            # Define packages by role
            Switch($NI_ROLE){
                hyperv {$NI_PACKAGE="Microsoft-NanoServer-SCVMM-Package"}
                iis {$NI_PACKAGE="Microsoft-NanoServer-IIS-Package"}
                dns {$NI_PACKAGE="Microsoft-NanoServer-DNS-Package"}
            }        
               
            # Create authentication        
            $CRED = new-object -typename System.Management.Automation.PSCredential -argumentlist $DC_USER, $ADMIN_PWD_SEC

            # Check connectivity 
            $error.clear()
            try{ Invoke-Command -VMName $DC_NAME -Credential $CRED -ScriptBlock{ Write-Host "Connection established to $env:COMPUTERNAME" -ForegroundColor Yellow } -ErrorAction SilentlyContinue }
            catch {"Connection error to $VM_NAME"}
            IF(!$error) {
    
                # Generate blob domain file
                Invoke-Command -VMName $DC_NAME -Credential $CRED `
                    -ArgumentList $NI_NAME, $BLOB_PATH, $DOMAIN_NAME `
                    -ScriptBlock{
                        # Set Variables by arguments
                        $NI_NAME     = $args[0]
                        $BLOB_PATH   = $args[1]
                        $DOMAIN_NAME = $args[2]
                    
                        # Create domainjoin directory
                        IF(!(Test-Path -Path ${BLOB_PATH})){
                            New-Item -ItemType directory -Path ${BLOB_PATH}
                        }

                        # Generate blob domain                    
                        IF(!(Test-Path -Path ${BLOB_PATH}\${NI_NAME})){                        
                            djoin.exe /provision /domain $DOMAIN_NAME /machine $NI_NAME /savefile ${BLOB_PATH}\${NI_NAME}
                        }
                        ELSE{
                            Write-Host "Blob of VM $NI_NAME already exists" -ForegroundColor Red
                        }
                    }

                # Get the content of the blob domain file
                $BLOB_CONTENT=Invoke-Command -VMName $DC_NAME -Credential $CRED `
                    -ArgumentList $NI_NAME, $BLOB_PATH, $DOMAIN_NAME `
                    -ScriptBlock{

                        # Set Variables by arguments
                        $NI_NAME     = $args[0]
                        $BLOB_PATH   = $args[1]
                        $DOMAIN_NAME = $args[2]

                        # Get the content of the blob file
                        Get-Content -Path ${BLOB_PATH}\${NI_NAME}
                    }
            }
            ELSE{
                Write-Host "Connection to $DC_NAME was not established" -ForegroundColor Red
                exit 1
            }

            # Copy blob content to a file on a host               
            IF(!(Test-Path -Path ${BLOB_PATH}\${NI_NAME})){            
                $BLOB_CONTENT > ${BLOB_PATH}\${NI_NAME}
            }
            ELSE{
                Write-Host "Blob of VM $NI_NAME already exists" -ForegroundColor Red
            }
            
            # Cleanup images directory
            IF(Test-Path -Path ${DIR_PATH}\${NI_NAME}){
                Get-ChildItem -Path ${DIR_PATH}\${NI_NAME} -Recurse | Remove-Item -Force -Recurse
            }
        
            # Create Nano Server Image for Hyper-V
            IF($NI_ROLE -eq "hyperv"){
                Write-Host "Creating the image of $NI_VM_NAME, please wait" -ForegroundColor Yellow        
                New-NanoServerImage `
                    -AdministratorPassword $ADMIN_PWD_SEC `
                    -MediaPath $MEDIA_DRIVE `
                    -BasePath ${DIR_PATH}\${NI_NAME} `
                    -TargetPath "${VMS_PATH}\${NI_VM_NAME}\Virtual Hard Disks\${NI_VM_NAME}_OS.vhd" `
                    -MaxSize $NI_HD `
                    -DeploymentType $DEPLOY_TYPE `
                    -Edition $EDITION `
                    -Ipv4Address $NI_IP `
                    -Ipv4SubnetMask $NIC_SUBNET `
                    -Ipv4Dns $NIC_DNS `
                    -InterfaceNameOrIndex $NIC_INDEX `
                    -DomainBlobPath ${BLOB_PATH}\${NI_NAME} `
                    -Compute -Clustering `
                    -SetupCompleteCommand "netsh advfirewall set allprofiles state off" `
                    -Package $NI_PACKAGE  
            }
            # Create Nano Server Image for other roles
            ELSE{
                Write-Host "Creating the image of $NI_VM_NAME, please wait" -ForegroundColor Yellow        
                New-NanoServerImage `
                    -AdministratorPassword $ADMIN_PWD_SEC `
                    -MediaPath $MEDIA_DRIVE `
                    -BasePath ${DIR_PATH}\${NI_NAME} `
                    -TargetPath "${VMS_PATH}\${NI_VM_NAME}\Virtual Hard Disks\${NI_VM_NAME}_OS.vhd" `
                    -MaxSize $NI_HD `
                    -DeploymentType $DEPLOY_TYPE `
                    -Edition $EDITION `
                    -Ipv4Address $NI_IP `
                    -Ipv4SubnetMask $NIC_SUBNET `
                    -Ipv4Dns $NIC_DNS `
                    -InterfaceNameOrIndex $NIC_INDEX `
                    -DomainBlobPath ${BLOB_PATH}\${NI_NAME} `
                    -Package $NI_PACKAGE `
                    -SetupCompleteCommand "netsh advfirewall set allprofiles state off"                
            }
        
            # Attach VHD to VM
            IF(!(Get-VMHardDiskDrive -VMName $NI_VM_NAME -ControllerLocation 0 -ControllerNumber 0 -ErrorAction SilentlyContinue)){
                Write-Host "VHD file ${VMS_PATH}\${NI_VM_NAME}\Virtual Hard Disks\${NI_VM_NAME}_OS.vhd was added" -ForegroundColor Yellow
                Add-VMHardDiskDrive -VMName $NI_VM_NAME `
                -Path "${VMS_PATH}\${NI_VM_NAME}\Virtual Hard Disks\${NI_VM_NAME}_OS.vhd" `
                -ControllerType IDE `
                -ControllerNumber 0 `
                -ControllerLocation 0
            }
            ELSE{
                Write-Host "IDE Controller is already allocated, please check the VHD." -ForegroundColor Green
            }
        
            # Start the VM
            IF($VM_STATUS=(Get-VM -VMName $NI_VM_NAME).State -eq "off"){
                Write-Host "Starting the VM $NI_VM_NAME, please wait." -ForegroundColor Yellow
                Start-VM -Name $NI_VM_NAME            
            }
            ELSE{
                Write-Host "VM $NI_VM_NAME is already started" -ForegroundColor Green
            }            
        }
        ELSE{
        Write-Host "The OS disk is already attached to VM $NI_VM_NAME" -ForegroundColor Green
        }
    }    
}
ELSE{
    Write-Host "Media drive of Windows Server 2016 was not located, please mount the media" -ForegroundColor Red
}