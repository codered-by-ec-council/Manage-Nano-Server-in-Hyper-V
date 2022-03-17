# Lab Resolution

- [Lab Resolution](#lab-resolution)
- [Setup Nano Server Image for VM IIS02 via Nano Server Image Builder](#setup-nano-server-image-for-vm-iis02-via-nano-server-image-builder)
- [Setup Nano Server Image for VM DNS02 via Powershell](#setup-nano-server-image-for-vm-dns02-via-powershell)

# Setup Nano Server Image for VM IIS02 via Nano Server Image Builder

- **Start [Nano Server Image Builder](https://docs.microsoft.com/en-us/windows-server/get-started/deploy-nano-server), and then select the option `Create a new Nano Server image`**
![Image_Builder](images/ImageBuilder_01.png)
</br></br>

- **Select the media mount path of Windows Server 2016 ISO file**
![Media source](images/ImageBuilder_02.png)
</br></br>

- **Accept the contract**
![Accept contract](images/ImageBuilder_03.png)
</br></br>

- **Set the `output file`**
![Output file](images/ImageBuilder_04.png)

- **Select the role**
![Role](images/ImageBuilder_05.png)
</br></br>

- **Set `hostname` and `password`**
![Hostname and password](images/ImageBuilder_06.png)
</br></br>

- **Select the option `Create basic Nano Server image`**
![Basic Nano server image](images/ImageBuilder_07.png)
</br></br>

- **Review Setings and then click on `Create`**
![Review Settings](images/ImageBuilder_08.png)
</br></br>

- **Wait until process is completed**
![Wait](images/ImageBuilder_09.png)
</br></br>

- **Edit the settings of `IIS02` VM**
 
![Edit IIS02](images/ImageBuilder_10.png)
</br></br>

- **Add VHD file**
![Add VHD file](images/ImageBuilder_11.png)
</br></br>

- **Set VHD file location**
![VDH file location](images/ImageBuilder_12.png)
</br></br>
</br></br>

# Setup Nano Server Image for VM DNS02 via Powershell

It is necessary to run the steps described on script [deploy_dns02.ps1](deploy_dns02.ps1)

During the execution of the script, it is expected via Powershell to run the actions:
- Generate the Blob domain file to join Nano Server on domain
- Import the module NanoServerImageGenerator
- Deploy Nano Server image via Powershell
- Attach VHD to VM
- Start the VM

***After the execution of those steps, it is expect that DNS02 VM will be ready.***
