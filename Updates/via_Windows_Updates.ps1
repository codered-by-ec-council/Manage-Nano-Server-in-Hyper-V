# Scan updates
$ci = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
$result = $ci | Invoke-CimMethod -MethodName ScanForUpdates -Arguments @{SearchCriteria="IsInstalled=0";OnlineScan=$true}
$result.Updates

# Install updates
Invoke-CimMethod -InputObject $ci -MethodName ApplyApplicableUpdates