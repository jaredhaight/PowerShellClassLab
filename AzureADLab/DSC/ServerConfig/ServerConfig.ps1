configuration HomeConfig 
{
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    )
  
  Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[Start] Got FileURL: $filesUrl"
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  Node localhost 
  {
    WindowsFeature FileServer
    {
        Ensure = "Present" 
        Name = "FS-FileServer"
    }
    WindowsFeature WebServer
    {
        Ensure = "Present" 
        Name = "Web-Server"
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

    Group AddLocalAdminsGroup
    {
        GroupName='Administrators'   
        Ensure= 'Present'             
        MembersToInclude= "$domain\LocalAdmins"
        Credential = $DomainCreds    
        PsDscRunAsCredential = $DomainCreds
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