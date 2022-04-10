# Define settings
$SERVER="HV01"

# List all methotds
Get-WmiObject -ComputerName $SERVER -List

# Get logical disks
Get-WmiObject -ComputerName $SERVER -ClassName Win32_LogicalDisk

# Get build number
Get-WmiObject -ComputerName $SERVER -Class Win32_OperatingSystem

# Get services with ExitCode 1077
Get-WmiObject -ComputerName $SERVER -Class Win32_Service -Filter ("(ExitCode = '1077')")

# Show process that HandleCount is greater than 200
Get-WmiObject -ComputerName $SERVER -Query "SELECT Name FROM Win32_Process WHERE HandleCount>=200" | Select-Object Name

# Shpw stopped services
Get-WmiObject -ComputerName $SERVER -Query "SELECT Name FROM Win32_Service WHERE 'Stopped'=State" | Select-Object Name