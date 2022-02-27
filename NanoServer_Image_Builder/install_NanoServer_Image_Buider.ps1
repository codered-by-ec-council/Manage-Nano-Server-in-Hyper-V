# Default variables
$TEMP_DIR="C:/Temp"

# Clear the screen
CLS

# Create temp directory
IF(!(Test-Path -Path $TEMP_DIR)){
    Write-Host "Creating the directory $TEMP_DIR" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $TEMP_DIR
}
ELSE{
    Write-Host "Directory $TEMP_DIR already exists" -ForegroundColor Green
}

# Download Windows ADK
IF(!(Test-Path -Path ${TEMP_DIR}\ADKSetup.exe)){
    Write-Host "Downloading Windows ADK, please wait" -ForegroundColor Yellow
    Invoke-WebRequest `
        -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=526740' `
        -OutFile "${TEMP_DIR}\ADKSetup.exe"
}ELSE{
    Write-Host "Windows ADK installation file already exists" -ForegroundColor Green
}


# Check if ADK features are installed
IF((Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Windows Deployment Tools"}) `
  -and (Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Windows PE x86 x64 wims"})){
    Write-Host "ADK Features for Nano Server Image Builder are already installed" -ForegroundColor Green
}
ELSE{
# Install Windows ADK
Write-Host "Installing ADK Features WinPE and Deployment Tools, please wait" -ForegroundColor Yellow
Start-Process `
    -FilePath "${TEMP_DIR}/ADKSetup.exe" `
    -ArgumentList "/features OptionId.DeploymentTools OptionId.WindowsPreInstallationEnvironment /quiet /log $TEMP_DIR/ADKSetup.log" `
    -Wait `
    -PassThru
}

# Download Nano Server Image Builder
IF(!(Test-Path -Path ${TEMP_DIR}/NanoServerImageBuilder.msi)){
    Write-Host "Dowloading Nano Server Image Builder installation file" -ForegroundColor Yellow
    Invoke-WebRequest `
        -Uri 'https://download.microsoft.com/download/0/6/F/06F4BA5D-6A43-4230-B5FE-6E24AD4E5BF4/NanoServerImageBuilder.msi' `
        -OutFile "${TEMP_DIR}/NanoServerImageBuilder.msi"
}
ELSE{
    Write-Host "Nano Server Image Builder installation file is already on ${TEMP_DIR}/NanoServerImageBuilder.msi" -ForegroundColor Green
}

# Install Nano Server Image Builder
IF(!(Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Nano Server Image Builder"})){
    Write-Host "Installing Nano Server Image Builder, please wait" -ForegroundColor Yellow
    Start-Process `
        -FilePath "${TEMP_DIR}/NanoServerImageBuilder.msi" `
        -ArgumentList "/qn /l*v ${TEMP_DIR}/NanoServerImageBuilder.log" `
        -Wait `
        -PassThru
}
ELSE{
    Write-Host "Nano Server Image Builder is already installed" -ForegroundColor Green
}

# Launch Nano Server Image Builder on Management Server
Start-Process `
    -FilePath 'C:\Program Files\Nano Server Image Builder\NanoServerImageBuilder.exe' 

<#
References:
https://social.technet.microsoft.com/wiki/contents/articles/36136.nano-server-getting-started-with-image-builder.aspx
#>