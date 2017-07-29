function New-AzureLabAccessRule {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory=$True)]
    [pscredential]$Credentials,

    [Parameter(Mandatory=$True)]
    [string]$SourceIpAddress,
    
    [int]$Port=3389,
    
    [string]$ResourceGroup="evil.training-master",
    
    [string[]]$NetworkSecurityGroups=('evil.training-nsg-eastus2','evil.training-nsg-westus2')
  )

  # Import Azure Service Management module
  Import-Module AzureRM  

  # Check if logged in to Azure
  Try {
    Get-AzureRMContext -ErrorAction Stop | Out-Null
  }
  Catch {
    Add-AzureRmAccount -Credential $Credentials
  }

  forEach ($nsgName in $NetworkSecurityGroups) {
    Write-Output "[*] Getting NSG: $nsgName"
    try {
      $nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $ResourceGroup -OutVariable $null
      $priorties = $nsg.SecurityRules.Priority
      $priority = $priorties[-1] + 1
    }
    catch {
      Write-Warning "Error Getting NSG: $nsgName"
      Write-Output $error[0]
      break
    }

    Write-Output "[*] New rule priority: $priority"
    Write-Output "[*] Adding rule to $nsgName"
    try {
      Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name "RDP-$Priority" -Direction Inbound `
        -Access Allow -SourceAddressPrefix $SourceIPAddress -SourcePortRange '*' -DestinationAddressPrefix '*' `
        -DestinationPortRange $Port -Protocol TCP -Priority $priority | Out-Null
    }
    catch {
      Write-Warning "Error adding rule to $nsgName"
      Write-Output $error[0]
      break
    }
    Write-Output "[*] Setting $nsgName"
    try {
      Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg | Out-Null
    }
    catch {
      Write-Warning "Error setting $nsgName"
      Write-Output $error[0]
      break
    }
  }
}