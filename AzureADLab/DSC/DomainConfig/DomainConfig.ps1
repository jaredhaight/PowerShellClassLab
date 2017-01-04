configuration DomainConfig 
{ 
  param 
  ( 
  [Parameter(Mandatory)]
  [String]$DomainName,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$Admincreds,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$StudentCreds,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$BackupExecCreds,

  [Parameter(Mandatory)]
  [Array]$Users,

  [Parameter(Mandatory)]
  [string]$filesUrl,

  [Int]$RetryCount=20,
  [Int]$RetryIntervalSec=30
  ) 

  Import-DscResource -ModuleName xActiveDirectory, xDisk, xNetworking, cDisk, PSDesiredStateConfiguration
  [System.Management.Automation.PSCredential]$DomainAdminCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  [System.Management.Automation.PSCredential]$DomainStudentCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($StudentCreds.UserName)", $StudentCreds.Password)
  [System.Management.Automation.PSCredential]$DomainBackupExecCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($BackupExecCreds.UserName)", $BackupExecCreds.Password)
  
  $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
  $InterfaceAlias=$($Interface.Name)

  Node localhost
  {
    Script AddADDSFeature {
      SetScript = {
        Add-WindowsFeature "AD-Domain-Services" -ErrorAction SilentlyContinue   
      }
      GetScript =  { @{} }
      TestScript = { $false }
    }
    Script DownloadBootstrapFiles
    {
        SetScript =  { 
            $file = $using:filesUrl + 'bootstrap.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadBootstrapFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\bootstrap.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\bootstrap.zip
         }
    }
    Archive UnzipBootstrapFiles
    {
        Ensure = "Present"
        Destination = "C:\Bootstrap"
        Path = "C:\Windows\Temp\Bootstrap.zip"
        Force = $true
        DependsOn = "[Script]DownloadBootstrapFiles"
    }
    Script ImportGPOs
    {
        SetScript =  { 
            Import-GPO -Path "C:\Bootstrap" -BackupId '{E3488702-D836-4F95-9E50-AD2844B0864C}' -TargetName "Server Permissions"
            Import-GPO -Path "C:\Bootstrap" -BackupId '{43D456E8-BED3-46F3-BD64-BF0A97913E36}' -TargetName "Class Default"
            New-GPLink -Name "Class Default" -Target "DC=AD,DC=EVIL,DC=TRAINING"
            New-GPLink -Name "Server Permissions" -Target "OU=SERVERS,OU=CLASS,DC=AD,DC=EVIL,DC=TRAINING"
        }
        GetScript =  { @{} }
        TestScript = { $false }
        DependsOn = "[Archive]UnzipBootstrapFiles","[xADOrganizationalUnit]ServersOU"
    }
    WindowsFeature DNS 
    { 
      Ensure = "Present" 
      Name = "DNS"		
    }

    Script script1
    {
      SetScript =  { 
        Set-DnsServerDiagnostics -All $true
        Write-Verbose -Verbose "Enabling DNS client diagnostics" 
      }
      GetScript =  { @{} }
      TestScript = { $false }
      DependsOn = "[WindowsFeature]DNS"
    }

    WindowsFeature DnsTools
    {
      Ensure = "Present"
      Name = "RSAT-DNS-Server"
    }

    xDnsServerAddress DnsServerAddress 
    { 
      Address        = '127.0.0.1' 
      InterfaceAlias = $InterfaceAlias
      AddressFamily  = 'IPv4'
      DependsOn = "[WindowsFeature]DNS"
    }

    xWaitforDisk Disk2
    {
      DiskNumber = 2
      RetryIntervalSec =$RetryIntervalSec
      RetryCount = $RetryCount
    }

    cDiskNoRestart ADDataDisk
    {
      DiskNumber = 2
      DriveLetter = "F"
    }

    WindowsFeature ADDSInstall 
    { 
      Ensure = "Present" 
      Name = "AD-Domain-Services"
      DependsOn="[cDiskNoRestart]ADDataDisk", "[Script]AddADDSFeature"
    } 

    xADDomain FirstDS 
    {
      DomainName = $DomainName
      DomainAdministratorCredential = $DomainAdminCreds
      SafemodeAdministratorPassword = $DomainAdminCreds
      DatabasePath = "F:\NTDS"
      LogPath = "F:\NTDS"
      SysvolPath = "F:\SYSVOL"
      DependsOn = "[WindowsFeature]ADDSInstall"
    } 
    xWaitForADDomain DscForestWait
    {
        DomainName = $DomainName
        DomainUserCredential = $DomainAdminCreds
        RetryCount = $RetryCount
        RetryIntervalSec = $RetryIntervalSec
        DependsOn = "[xADDomain]FirstDS"
    }
    xADGroup LocalAdmins
    {
      GroupName = "LocalAdmins"
      GroupScope = "Global"
      Category = "Security"
      Description = "Group for Local Admins"
      Ensure = 'Present'
      MembersToInclude = "StudentAdmin"
      Path = "OU=Groups,OU=Class,DC=ad,DC=evil,DC=training"
      DependsOn = "[xADOrganizationalUnit]GroupsOU", "[xADUser]StudentAdmin"
    }
    xADGroup RDPAccess
    {
      GroupName = "RDP Access"
      GroupScope = "Global"
      Category = "Security"
      Description = "Group for RDP Access"
      Ensure = 'Present'
      MembersToInclude = "StudentUser"
      Path = "OU=Groups,OU=Class,DC=ad,DC=evil,DC=training"
      DependsOn = "[xADOrganizationalUnit]GroupsOU", "[xADUser]StudentUser"
    }
    xADGroup DomainAdmins
    {
      GroupName = "Domain Admins"
      Ensure = 'Present'
      MembersToInclude = "BackupExec"
      DependsOn = "[xADUser]BackupExecUser"
    }
    xADOrganizationalUnit ClassOU
    {
      Name = "Class"
      Path = "DC=ad,DC=evil,DC=training"
      Ensure = 'Present'
      DependsOn = "[xWaitForADDomain]DscForestWait"
    }
    xADOrganizationalUnit UsersOU
    {
      Name = "Users"
      Path = "OU=class,DC=ad,DC=evil,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADOrganizationalUnit ComputersOU
    {
      Name = "Computers"
      Path = "OU=class,DC=ad,DC=evil,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADOrganizationalUnit ServersOU
    {
      Name = "Servers"
      Path = "OU=class,DC=ad,DC=evil,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADOrganizationalUnit GroupsOU
    {
      Name = "Groups"
      Path = "OU=class,DC=ad,DC=evil,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADOrganizationalUnit ServiceAccountsOU
    {
      Name = "Service Accounts"
      Path = "OU=class,DC=ad,DC=evil,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADUser StudentUser
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = "StudentUser"
        Password = $DomainStudentCreds
        Ensure = "Present"
        Path = "OU=Users,OU=Class,DC=ad,DC=evil,DC=training"
        DependsOn = "[xADOrganizationalUnit]UsersOU"
    }
    xADUser StudentAdmin
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = "StudentAdmin"
        Password = $DomainStudentCreds
        Ensure = "Present"
        Path = "OU=Users,OU=Class,DC=ad,DC=evil,DC=training"
        DependsOn = "[xADOrganizationalUnit]UsersOU"
    }
    xADUser BackupExecUser
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = "BackupExec"
        Password = $DomainBackupExecCreds
        Ensure = "Present"
        Path = "OU=Service Accounts,OU=Class,DC=ad,DC=evil,DC=training"
        DependsOn = "[xADOrganizationalUnit]ServiceAccountsOU"
    }
    forEach ($user in $users) {
      $Password = $User.Password + "ae23K#"
      $userCreds =  [System.Management.Automation.PSCredential]$DomainStudentCreds = New-Object System.Management.Automation.PSCredential("${DomainName}\$($User.UserName)", $Password)
      xADUser $user.username
      {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = "StudentAdmin"
        Password = $userCreds
        DisplayName = $user.first_name + " " + $user.last_name
        GivenName = $user.first_name
        Surname = $user.last_name
        JobTitle = $user.title
        Ensure = "Present"
        Path = "OU=Users,OU=Class,DC=ad,DC=evil,DC=training"
        DependsOn = "[xADOrganizationalUnit]UsersOU"
      }
    }
    LocalConfigurationManager 
    {
      ConfigurationMode = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }
  }
} 