# Scan updates
$ci = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
$result = $ci | Invoke-CimMethod -MethodName ScanForUpdates -Arguments @{SearchCriteria="IsInstalled=0";OnlineScan=$true}
$result.Updates

# Install updates
$ci = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
Invoke-CimMethod -InputObject $ci -MethodName ApplyApplicableUpdates
Restart-Computer; exit

# Get a list of installed updates
Get-WindowsPackage -Online | Where-Object {$_.PackageState -eq "Installed"}