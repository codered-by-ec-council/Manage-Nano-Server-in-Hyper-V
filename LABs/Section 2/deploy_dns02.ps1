# Generate BlobPath
djoin.exe /provision /domain "eccouncil.local" /machine "DNS02" /savefile "C:\DomJoin\DNS02" # Run on DC01

# Convert Admin password to secure
$ADMIN_PWD_SEC = ConvertTo-SecureString -String "P@ssw0rd" -AsPlainText -Force
 
# Import module
Import-Module "E:\NanoServer\NanoServerImageGenerator\NanoServerImageGenerator.psm1"

# Deploy Nano Server Image
New-NanoServerImage `
    -AdministratorPassword $ADMIN_PWD_SEC `
    -MediaPath "E:" `
    -BasePath "C:\NanoImages\DNS02" `
    -TargetPath "C:\VMs\ECCOUNCIL_DNS02\Virtual Hard Disks\DNS02_OS.vhd" `
    -MaxSize 8GB `
    -DeploymentType "Guest" `
    -Edition "Datacenter" `
    -Ipv4Address "10.0.0.60" `
    -Ipv4SubnetMask "255.255.255.0" `
    -Ipv4Dns "10.0.0.10" `
    -InterfaceNameOrIndex "Ethernet" `
    -DomainBlobPath "C:\DomJoin\DNS02" `
    -Package "Microsoft-NanoServer-DNS-Package" `
    -SetupCompleteCommand "netsh advfirewall set allprofiles state off" 

# Attach VHD to VM
Add-VMHardDiskDrive -VMName "ECCOUNCIL_DNS02" `
    -Path "C:\VMs\ECCOUNCIL_DNS02\Virtual Hard Disks\DNS02_OS.vhd" `
    -ControllerType IDE `
    -ControllerNumber 0 `
    -ControllerLocation 0

# Start VM
Start-VM "ECCOUNCIL_DNS02"