configuration ServerConfig {
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$ArtifactsUrl,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

  Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
  Node localhost {
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
    WindowsFeature RSATRemoteDesktop
    {
        Ensure = "Present" 
        Name = "RSAT-RD-Server"
    }
    WindowsFeature GPMC
    {
        Ensure = "Present" 
        Name = "GPMC"
    }
    LocalConfigurationManager 
    {
        ConfigurationMode = 'ApplyOnly'
        RebootNodeIfNeeded = $true
    }
  }
}