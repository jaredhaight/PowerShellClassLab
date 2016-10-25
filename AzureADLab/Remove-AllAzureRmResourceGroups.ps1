function Remove-AllAzureRmResourceGroups {
  Import-Module Azure
  Import-Module AzureRM

  # Check if logged in to Azure
  Try {
    Write-Verbose "[*] Getting list of Resource Groups.."
    $resourceGroups = Get-AzureRmResourceGroup -ErrorAction Stop
  }
  Catch [Microsoft.Azure.Commands.Common.Authentication.AadAuthenticationFailedException] {
    Write-Verbose "[*] Received Azure Authentication Failure message. Prompting for Login.."
    Login-AzureRmAccount
    Write-Verbose "[*] Getting list of Resource Groups.."
    $resourceGroups = Get-AzureRmResourceGroup
  }
  Catch [System.Management.Automation.PSInvalidOperationException] {
    Write-Verbose "[*] Received Azure Authentication Invalid Operation message. Prompting for Login.."
    Login-AzureRmAccount
    Write-Verbose "[*] Getting list of Resource Groups.."
    $resourceGroups = Get-AzureRmResourceGroup
  }
  Catch {
    Write-Warning "[!] Caught the following error"
    Write-Output $_.Exception.Message
    break
  }

  if ($resourceGroups.Count -gt 0) {
    forEach ($resourceGroup in $resourceGroups) {
        $resourceGroupName = $resourceGroup.ResourceGroupName.toString()
        if ($resourceGroupName -notlike "*master") {
            Write-Output "[*] Removing $resourceGroupName).."
            Remove-AzureRmResourceGroup -Name $resourceGroupName -Force
        }
    }
  }
  else {
    Write-Output "No Resource Groups Found"
  }

}