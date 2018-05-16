function Get-ClassDeploymentStatus {
  $rgs = Get-AzureRmResourceGroup
  $results = @()
  forEach ($rg in $rgs) {
    $result = Get-AzureRmResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName | Select ResourceGroupName, ProvisioningState
    $results += $result
  }
  return $results
}