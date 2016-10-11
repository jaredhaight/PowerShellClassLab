Configuration CreateClient {
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$DomainJoinCreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 

  Param($nodeName)
  Import-DscResource -ModuleName xComputerManagement
  [System.Management.Automation.PSCredential ]$DomainJoinCreds = New-Object System.Management.Automation.PSCredential ("$DomainName\$($domainJoin.UserName)", $domainJoin.Password)
  
  Node $AllNodes.NodeName {
  
    LocalConfigurationManager
    {
        ActionAfterReboot = 'ContinueConfiguration'
        ConfigurationMode = 'ApplyOnly'
        RebootNodeIfNeeded = $true
        AllowModuleOverWrite = $true
    }
    
    xComputer NewNameAndJoinDomain {
      Name = $AllNodes.NodeName
      DomainName = $domainName
      Credential = $DomainJoinCreds
    }
    
  }
}