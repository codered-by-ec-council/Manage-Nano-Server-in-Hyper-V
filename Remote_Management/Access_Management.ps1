# Define settings
$SERVER="HV01"

# List local users
Invoke-Command -ComputerName $SERVER -ScriptBlock{ Get-LocalUser }

# List local groups
Invoke-Command -ComputerName $SERVER -ScriptBlock{ Get-LocalGroup }

# List members of administrators group
Invoke-Command -ComputerName $SERVER -ScriptBlock{ Get-LocalGroupMember -Group "Administrators" }

# Create a new local user
Invoke-Command -ComputerName $SERVER -ScriptBlock{ New-LocalUser -Name "User1" -NoPassword }

# Add user as member of Administrators group
Invoke-Command -ComputerName $SERVER -ScriptBlock{ Add-LocalGroupMember -Group "Administrators" -Member "User1" }