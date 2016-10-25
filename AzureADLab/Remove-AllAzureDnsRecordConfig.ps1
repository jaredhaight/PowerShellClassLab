Import-Module Azure
Import-Module AzureRM
  
workflow Remove-AllAzureRmDnsRecordSets {
  
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)]
    [pscredential]$credentials,
    
    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$zoneName
    
  )
  $username = $credentials.UserName.ToString()
  Write-Output "Logging in as $username"
  Add-AzureRmAccount -Credential $credentials
  $dnsRecordSets = Get-AzureRMDnsRecordSet -ZoneName $zoneName -ResourceGroupName $resourceGroupName
 
  if ($dnsRecordSets.Count -gt 0) {
    forEach -parallel -throttle 15 ($dnsRecordSet in $dnsRecordSets) {
      if ($dnsRecordSet.RecordType -eq "A") {
        $dnsName = $dnsRecordSet.Name.toString()
        Write-Output "Removing $dnsName"
        Remove-AzureRmDnsRecordSet -RecordSet $dnsRecordSet
      }
    }
  }
  else {
    Write-Output "No DNS RecordSets found"
  }
}