workflow Stop-ClassVM {
  [cmdletbinding()]
  param(
    [ValidateSet('LinuxVM', 'DomainControllerVM', 'HomeVM', 'ServerVM', 'All')]
    [Parameter(Mandatory = $true)]
    [string]$Type,
    [Parameter(Mandatory = $true)]
    [PSCredential]$Credential
  )
  
  Connect-AzureRmAccount -Credential $credential

  if ($Type -eq 'All') {    
    $vms = Get-AzureRmVm
  }
  else {
    $resources = Find-AzureRmResource -Tag @{"DisplayName" = "$type"}
    $vms = $resources | Get-AzureRmVM
  }
  
  if ($vms -ne $null) {
    ForEach -Parallel -ThrottleLimit 20 ($vm in $vms) {
      Write-Verbose "[*] Stopping $($VM.Name)"
      Connect-AzureRmAccount -Credential $credential
      Stop-AzureRmVm -Name $($vm.Name) -ResourceGroupName $($Vm.ResourceGroupName) -Force
    }
  }
  else {
    Write-Warning "No resouces found."
    
  }
}

workflow Start-ClassVM {
  [cmdletbinding()]
  param(
    [ValidateSet('LinuxVM', 'DomainControllerVM', 'HomeVM', 'ServerVM', 'All')]
    [Parameter(Mandatory = $true)]
    [string]$Type,
    [Parameter(Mandatory = $true)]
    [PSCredential]$Credential
  )

  Connect-AzureRmAccount -Credential $credential
  
  if ($Type -eq 'All') {    
    $vms = Get-AzureRmVm
  }
  else {
    $resources = Find-AzureRmResource -Tag @{"DisplayName" = "$type"}
    $vms = $resources | Get-AzureRmVM
  }
  
  if ($vms -ne $null) {
    ForEach -Parallel -ThrottleLimit 20 ($vm in $vms) {
      Write-Verbose "[*] Starting $($VM.Name)"
      Connect-AzureRmAccount -Credential $credential 
      Start-AzureRmVm -Name $($vm.Name) -ResourceGroupName $($Vm.ResourceGroupName) 
    }
  }
  else {
    Write-Warning "No resouces found."
    
  }
}