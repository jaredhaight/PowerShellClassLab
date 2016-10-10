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
  
  Node $nodeName {
    xComputer NewNameAndJoinDomain {
      Name = $nodeName
      DomainName = $domainName
      Credential = $DomainJoinCreds
    }
    
  }
}