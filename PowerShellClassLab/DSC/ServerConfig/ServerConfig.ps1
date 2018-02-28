configuration ServerConfig 
{
  param 
  ( 
    [Parameter(Mandatory)]
    [String]$DomainName,
    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$Admincreds,
    [Parameter(Mandatory)]
    [String]$filesUrl
  )
  
  Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[Start] Got FileURL: $filesUrl"
  Import-DscResource -ModuleName xSmbShare, PSDesiredStateConfiguration, xWindowsUpdate, cChoco
  Import-DscResource -ModuleName xComputerManagement -Name xScheduledTask

  [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  
  Node localhost 
  {
    WindowsFeature FileServer {
      Ensure = "Present" 
      Name   = "FS-FileServer"
    }
    WindowsFeature WebServer {
      Ensure = "Present" 
      Name   = "Web-Server"
    }
    Script DisableFirewall {
      SetScript  = { 
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DisableFirewall] Running.."
        Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
      }
      GetScript  = { @{} }
      TestScript = { $false }
    }

    Group AddLocalAdminsGroup {
      GroupName            = 'Administrators'   
      Ensure               = 'Present'             
      MembersToInclude     = "$DomainName\LocalAdmins"
      Credential           = $DomainCreds    
      PsDscRunAsCredential = $DomainCreds
    }
    Group AddRDPAccessGroup {
      GroupName            = 'Remote Desktop Users'   
      Ensure               = 'Present'             
      MembersToInclude     = "$DomainName\RDP Access"
      Credential           = $DomainCreds    
      PsDscRunAsCredential = $DomainCreds
    }
    File DataFolder {
      Ensure          = "Present"
      DestinationPath = "C:\Data"
      Type            = "Directory"
      Force           = $true
    }
    xSmbShare DataShare
    {
      Ensure     = "Present" 
      Name       = "Data"
      Path       = "C:\Data"  
      FullAccess = "Everyone"
      DependsOn  = "[File]DataFolder"
    }    
    Script UpdateHelp {
      SetScript  = { 
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[UpdateHelp] Running.."
        Update-Help -Force -ErrorAction SilentlyContinue
      }
      GetScript  = { @{} }
      TestScript = { $false }
    }   
    cChocoInstaller installChoco
    {
      InstallDir = "c:\choco"
    }
    cChocoPackageInstaller installBGinfo
    {
      Name        = "bginfo"
      DependsOn   = "[cChocoInstaller]installChoco"
      AutoUpgrade = $True
    }
    Script DownloadBGIFile {
      SetScript  = { 
        $file = $using:filesUrl + 'LAB.bgi'
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadBGIFile] Downloading $file"
        Invoke-WebRequest -Uri $file -OutFile C:\LAB.bgi
      }
      GetScript  = { @{} }
      TestScript = { 
        Test-Path C:\LAB.bgi
      }
    }
    xScheduledTask xScheduledTaskLogonAdd
    {
      TaskName         = 'BGinfo'
      ActionExecutable = 'C:\ProgramData\chocolatey\bin\Bginfo.exe'
      ActionArguments  = 'C:\LAB.bgi'
      ScheduleType     = 'AtLogOn'
    }
    LocalConfigurationManager {
      ConfigurationMode  = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }
  }
}