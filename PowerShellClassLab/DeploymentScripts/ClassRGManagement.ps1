workflow Remove-ClassResourceGroups {
  
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)]
    [pscredential]$Credentials
  )

  $username = $credentials.UserName.ToString()
  Write-Output "Logging in as $username"
  Connect-AzureRmAccount -Credential $Credentials
    
  $resourceGroups = Get-AzureRmResourceGroup -ErrorAction Stop
 
  if ($resourceGroups.Count -gt 0) {
    forEach -parallel -throttle 15 ($resourceGroup in $resourceGroups) {
        $resourceGroupName = $resourceGroup.ResourceGroupName.toString()
        if ($resourceGroupName -notlike "*master") {
          Connect-AzureRmAccount -Credential $Credentials
          Write-Output "[*] Removing $resourceGroupName.."
          Remove-AzureRmResourceGroup -Name $resourceGroupName -Force
        }
    }
  }
  else {
    Write-Output "No Resource Groups Found"
  }

}