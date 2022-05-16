# Default variables
$VM_USER     = "eccouncil\Administrator" # Username for authentication
$VM_PASSWORD = "P@ssw0rd" # Password for authentication
$VM_NAME     = "ECCOUNCIL_SCVMM"

# Cluster settings
$CLUSTER_NAME  = "nanoCluster" # Name of the cluster
$CLUSTER_NODES = ("hv01","hv02") # Name of the nodes that composes the cluster
$CLUSTER_IP    = "10.0.0.250" # IP of cluster

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
        $CLUSTER_NAME, $CLUSTER_NODES, $CLUSTER_IP `
        -Credential $CRED `
        -ScriptBlock{
            # Set Variables by arguments
            $CLUSTER_NAME     = $args[0]
            $CLUSTER_NODES    = $args[1]
            $CLUSTER_IP       = $args[2]
            
            # Create the cluster
            New-Cluster -Name $CLUSTER_NAME -Node $CLUSTER_NODES -NoStorage -StaticAddress $CLUSTER_IP
        }
}