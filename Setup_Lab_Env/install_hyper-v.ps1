# Install Hyper-V role and required features for management (Restart may be required)
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

<# 
References:
- https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/install-the-hyper-v-role-on-windows-server
#>