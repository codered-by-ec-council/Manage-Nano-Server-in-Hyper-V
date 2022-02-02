# 

$VMs = @()
$VMsCounter ++

$VMs += ,@($VMsCounter, 'DC01',1024,'dyn','yes',50)
$VMsCounter ++

$VMs += ,@($VMsCounter, 'WEB01',512,'dyn','yes',10)
$VMsCounter ++

$VMs += ,@($VMsCounter, 'DNS01',512,'dyn','yes',10)
$VMsCounter ++

$VMs += ,@($VMsCounter, 'HV01',2048,'sta','yes',100)
$VMsCounter ++

$VMs += ,@($VMsCounter, 'HV01',2048,'sta','yes',100)
$VMsCounter ++


foreach($VM in $VMs){

    Write-host ($VM)
}