# Default variables
$VM_USER     = "eccouncil\Administrator" # Username for authentication
$VM_PASSWORD = "P@ssw0rd" # Password for authentication
$VM_NAME     = "ECCOUNCIL_SCVMM"

# Cluster settings
$CLUSTER_NAME  = "nanoCluster" # Name of the cluster
$CLUSTER_NODES = "hv01,hv02" # Name of the nodes that composes the cluster
$CLUSTER_IP    = "10.0.0.250" # IP of cluster

# Share settings
$SHARE_PATH       = "V:\VMs" # Path of the share
$SHARE_NAME       = "VMs" # Name of the share
$SHARE_FULLACCESS = ("eccouncil\HV01$", "eccouncil\HV02$", "eccouncil\nanoCluster$", "eccouncil\Domain Admins", "Administrators") # Access of the share


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
        $CLUSTER_NAME, $CLUSTER_NODES, $CLUSTER_IP, `
        $SHARE_PATH, $SHARE_NAME, $SHARE_FULLACCESS `
        -Credential $CRED `
        -ScriptBlock{
            # Set Variables by arguments
            $CLUSTER_NAME     = $args[0]
            $CLUSTER_NODES    = $args[1]
            $CLUSTER_IP       = $args[2]
            $SHARE_PATH       = $args[3]
            $SHARE_NAME       = $args[4]
            $SHARE_FULLACCESS = $args[5]

            # Create the cluster
            New-Cluster -Name $CLUSTER_NAME -Node $CLUSTER_NODES -NoStorage -StaticAddress $CLUSTER_IP
                    
            # Create folder
            New-Item -ItemType Directory -Path $SHARE_PATH

            # Create file share
            New-SmbShare -Name $SHARE_NAME -Path $SHARE_PATH -FullAccess $SHARE_FULLACCESS

            # Set NTFS permissions from the file share permissions
            Set-SmbPathAcl -ShareName $SHARE_NAME
        }
}