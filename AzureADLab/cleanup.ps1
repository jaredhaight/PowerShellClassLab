Import-Module Azure
Import-Module AzureRM

# Check if logged in to Azure
Try {
  $resourceGroups = Get-AzureRmResourceGroup -ErrorAction Stop
}
Catch [Microsoft.Azure.Commands.Common.Authentication.AadAuthenticationFailedException] {
  Login-AzureRmAccount
  $resourceGroups = Get-AzureRmResourceGroup
}



forEach ($resourceGroup in $resourceGroups) {
    if ($resourceGroup.ResourceGroupName -notlike "*master") {
        Remove-AzureRmResourceGroup -Name $resourceGroup.ResourceGroupName -Force -Verbose
    }
}