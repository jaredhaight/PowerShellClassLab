Import-Module Azure
Import-Module AzureRM

# Check if logged in to Azure
Try {
  Get-AzureRMContext -ErrorAction Stop
}
Catch {
  Login-AzureRmAccount
}

$resourceGroups = Get-AzureRmResourceGroup

forEach ($resourceGroup in $resourceGroups) {
    if ($resourceGroup.ResourceGroupName -notcontains "master") {
        Remove-AzureRmResourceGroup -Name $resourceGroup.ResourceGroupName -Force -Verbose
    }
}