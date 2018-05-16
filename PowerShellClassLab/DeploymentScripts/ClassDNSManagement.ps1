function New-ClassDnsRecordSets {
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)]
    [pscredential]$Credentials,
    [string]$ResourceGroupName='evil.training-master',
    [string]$ZoneName='evil.training'
  )
  if ((Get-AzureRmContext).Account -eq $null) {
    Connect-AzureRmAccount -Credential $Credentials
  }

  $vms = Get-AzureRmResource -ResourceType "Microsoft.Compute/VirtualMachines" -Tag @{"displayName"="ClientVM"}

  ForEach ($vm in $vms) {
    $ARecord = "$($vm.Name).$($vm.Location).cloudapp.azure.com"
    $CnameRecord = New-AzureRmDnsRecordConfig -Cname $ARecord
    Write-Output "[i] Mapping $ARecord to $($vm.Name).$ZoneName"
    New-AzureRmDnsRecordSet -Name $vm.Name -RecordType "CNAME" -ZoneName $ZoneName -ResourceGroupName $ResourceGroupName -Ttl 10 -DnsRecords $CnameRecord | Out-Null
  }
}

workflow Remove-ClassDnsRecordSets {
  
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)]
    [pscredential]$Credentials,
    [string]$ResourceGroupName='evil.training-master',
    [string]$ZoneName='evil.training'
    
  )
  $username = $credentials.UserName.ToString()
  Write-Output "Logging in as $username"
  if ((Get-AzureRmContext).Account -eq $null) {
    Connect-AzureRmAccount -Credential $Credentials
  }
  $dnsRecordSets = Get-AzureRMDnsRecordSet -ZoneName $zoneName -ResourceGroupName $resourceGroupName
 
  if ($dnsRecordSets.Count -gt 0) {
    forEach -parallel -throttle 15 ($dnsRecordSet in $dnsRecordSets) {
      if ($dnsRecordSet.RecordType -eq "CNAME") {
        Connect-AzureRmAccount -Credential $Credentials
        $dnsName = $dnsRecordSet.Name.toString()
        Write-Output "Removing $dnsName"
        Remove-AzureRmDnsRecordSet -Name $dnsRecordSet.Name -RecordType "CNAME" -ZoneName $zoneName -ResourceGroupName $resourceGroupName
      }
    }
  }
  else {
    Write-Output "No DNS RecordSets found"
  }
}