Enable-WindowsOptionalFeature -Online -FeatureName DNS-Server-Full-Role
import-module DNSServer
Get-Command -Module DNSServer
