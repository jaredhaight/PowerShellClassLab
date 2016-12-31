configuration HomeConfig 
{
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$filesUrl
    )
  
  Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[Start] Got FileURL: $filesUrl"
  Import-DscResource -ModuleName PSDesiredStateConfiguration

  Node localhost 
  {
    WindowsFeature ADTools
    {
        Ensure = "Present" 
        Name = "RSAT-AD-Tools"
    }
    WindowsFeature ADAdminCenter
    {
        Ensure = "Present" 
        Name = "RSAT-AD-AdminCenter"
    }
    WindowsFeature ADDSTools
    {
        Ensure = "Present" 
        Name = "RSAT-ADDS-Tools"
    }
    WindowsFeature ADPowerShell
    {
        Ensure = "Present" 
        Name = "RSAT-AD-PowerShell"
    }
    WindowsFeature RSATDNS
    {
        Ensure = "Present" 
        Name = "RSAT-DNS-Server"
    }
    WindowsFeature RSATFileServices
    {
        Ensure = "Present" 
        Name = "RSAT-File-Services"
    }
    WindowsFeature GPMC
    {
        Ensure = "Present" 
        Name = "GPMC"
    }
    Registry IEESC-Admin
    {
        Ensure = "Present"
        Key = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
        ValueName = "IsInstalled"
        ValueData = "0"
    }
    Registry IEESC-User
    {
        Ensure = "Present"
        Key = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
        ValueName = "IsInstalled"
        ValueData = "0"
    }
    Script DisableFirewall
    {
        SetScript =  { 
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DisableFirewall] Running.."
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
        }
        GetScript =  { @{} }
        TestScript = { $false }
    }
    Script DownloadClassFiles
    {
        SetScript =  { 
            $file = $filesUrl + 'class.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadClassFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\Class.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\class.zip
         }
    }
    Script DownloadBootstrapFiles
    {
        SetScript =  { 
            $file = $filesUrl + 'bootstrap.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadBootstrapFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\bootstrap.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\bootstrap.zip
         }
    }
    Script UpdateHelp
    {
        SetScript =  { 
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[UpdateHelp] Running.."
            Update-Help -Force
        }
        GetScript =  { @{} }
        TestScript = { $false }
    }
    LocalConfigurationManager 
    {
        ConfigurationMode = 'ApplyOnly'
        RebootNodeIfNeeded = $true
    }
  }
}