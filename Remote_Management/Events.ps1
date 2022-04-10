# Define settings
$SERVER="HV01"
$EVENT_TYPE="Application" # System or Application
$EVENT_PERIOD="-30" # Time in days

# Get all events
Get-WmiObject -ComputerName $SERVER `
    -Class Win32_NTLogEvent
   
# Get all events from a specific type 
Get-WmiObject -ComputerName $SERVER `
    -Class Win32_NTLogEvent `
    -Filter ("(logfile='$EVENT_TYPE')")
        

# Get all events from a specific type and period
Get-WmiObject -ComputerName $SERVER `
    -Class Win32_NTLogEvent `
    -Filter ( `
        "(logfile='Application' " + "AND `
         (TimeWritten >'$([System.Management.ManagementDateTimeConverter]::ToDMTFDateTime((get-date).AddDays($EVENT_PERIOD)))'))" `
    )