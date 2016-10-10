configuration CreateADDomainWithData
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory, xStorage

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("$DomainName\$($AdminCreds.UserName)", $AdminCreds.Password)

    Node $AllNodes.NodeName
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
            AllowModuleOverWrite = $true
        }

        xWaitforDisk Disk2
        {
             DiskNumber = 2
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }

        xDisk ADDataDisk
        {
            DiskNumber = 2
            DriveLetter = 'F'
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
        }  

        # Optional GUI tools
        WindowsFeature ADDSTools
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADDS' 
        }

        xADDomain FirstDS 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = 'F:\NTDS'
            LogPath = 'F:\NTDS'
            SysvolPath = 'F:\SYSVOL'
            #DependsOn = "[WindowsFeature]ADDSInstall","[xDnsServerAddress]DnsServerAddress","[cDiskNoRestart]ADDataDisk"
            DependsOn = "[WindowsFeature]ADDSInstall","[xDisk]ADDataDisk"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential = $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[xADDomain]FirstDS"
        } 

        xADRecycleBin RecycleBin
        {
           EnterpriseAdministratorCredential = $DomainCreds
           ForestFQDN = $DomainName
           DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        ### OUs ###
        $DomainRoot = "DC=$($DomainName -replace '\.',',DC=')"
        $DependsOn_OU = @()

        ForEach ($RootOU in $ConfigurationData.NonNodeData.RootOUs) {

            xADOrganizationalUnit "OU_$RootOU"
            {
                Name = $RootOU
                Path = $DomainRoot
                ProtectedFromAccidentalDeletion = $true
                Description = "OU for $RootOU"
                Credential = $DomainCred
                Ensure = 'Present'
                DependsOn = '[xADRecycleBin]RecycleBin'
            }

            ForEach ($ChildOU in $ConfigurationData.NonNodeData.ChildOUs) {
                
                xADOrganizationalUnit "OU_$($RootOU)_$ChildOU"
                {
                    Name = $ChildOU
                    Path = "OU=$RootOU,$DomainRoot"
                    ProtectedFromAccidentalDeletion = $true
                    Credential = $DomainCred
                    Ensure = 'Present'
                    DependsOn = "[xADOrganizationalUnit]OU_$RootOU"
                }

                $DependsOn_OU += "[xADOrganizationalUnit]OU_$($RootOU)_$ChildOU"
            }

        }


        ### USERS ###
        $DependsOn_User = @()
        $Users = $ConfigurationData.NonNodeData.UserData | ConvertFrom-CSV
        ForEach ($User in $Users) {

            xADUser "NewADUser_$($User.UserName)"
            {
                DomainName = $DomainName
                Ensure = 'Present'
                UserName = $User.UserName
                JobTitle = $User.Title
                Path = "OU=Users,OU=$($User.Dept),$DomainRoot"
                Enabled = $true
                Password = New-Object -TypeName PSCredential -ArgumentList 'JustPassword', (ConvertTo-SecureString -String $User.Password -AsPlainText -Force)
                DependsOn = $DependsOn_OU
            }
            $DependsOn_User += "[xADUser]NewADUser_$($User.UserName)"
        }

        1..$ConfigurationData.NonNodeData.TestObjCount | ForEach-Object {

            xADUser "NewADUser_$_"
            {
                DomainName = $DomainName
                Ensure = 'Present'
                UserName = "TestUser$_"
                Enabled = $false  # Must specify $false if disabled and no password
                DependsOn = '[xADRecycleBin]RecycleBin'
            }

        }


        ### GROUPS ###
        ForEach ($RootOU in $ConfigurationData.NonNodeData.RootOUs) {
            xADGroup "NewADGroup_$RootOU"
            {
                GroupName = "G_$RootOU"
                GroupScope = 'Global'
                Description = "Global group for $RootOU"
                Category = 'Security'
                Members = ($Users | Where-Object {$_.Dept -eq $RootOU}).UserName
                Path = "OU=Groups,OU=$RootOU,$DomainRoot"
                Ensure = 'Present'
                DependsOn = $DependsOn_User
            }
        }

        1..$ConfigurationData.NonNodeData.TestObjCount | ForEach-Object {

            xADGroup "NewADGroup_$_"
            {
                GroupName = "TestGroup$_"
                GroupScope = 'Global'
                Category = 'Security'
                Members = "TestUser$_"
                Ensure = 'Present'
                DependsOn = "[xADUser]NewADUser_$_"
            }

        }


   }
}
