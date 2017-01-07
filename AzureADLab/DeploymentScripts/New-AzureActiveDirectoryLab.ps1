workflow New-AzureActiveDirectoryLab {

  [CmdletBinding()]
  Param( 
    [Parameter(Mandatory=$True,Position=1)]
    [pscredential]$Credentials,

    [Parameter(Mandatory=$True,Position=2)]
    [string]$CsvSource
  ) 

  $studentData = Import-CSV $csvSource
  foreach -parallel -throttle 20 ($student in $studentData) {
     $studentPassword = $student.password
     $studentCode = $student.code.toString()
     $studentNumber = $student.id
     $region = 'eastus2'
     
     if ($studentNumber % 2 -eq 0) {
       $region = 'westus2'
     }
     Write-Output "Sending $studentCode to $region"
     Invoke-CreateAzureActiveDirectoryLab -credentials $credentials -studentCode $studentCode -studentPassword $studentPassword -region $region -place $studentNumber -total $studentData.count 
   }
}

function Invoke-CreateAzureActiveDirectoryLab {
  
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True)]
    [pscredential]$Credentials,

    [Parameter(Mandatory=$True)]
    [string]$StudentCode,
    
    [Parameter(Mandatory=$True)]
    [string]$StudentPassword,

    [Parameter(Mandatory=$True)]
    [string]$BackupExecPassword,

    [string]$Region="eastus2",
    [int]$place=1,
    [int]$total=1,
    [switch]$Test
  )

  # Import Azure Service Management module
  Import-Module Azure
  Import-Module AzureRM
  
  Write-Output "$place/$total - Starting deployment for $studentCode"  

  # Check if logged in to Azure
  Try {
    Get-AzureRMContext -ErrorAction Stop
  }
  Catch {
    Add-AzureRmAccount -Credential $credentials
  }

  
  # Common Variables
  $location                   = $region
  $locationName               = "East US"
  $masterResourceGroup        = "evil.training-master"
  $dnsZone                    = "evil.training"
  $resourceGroupName          = $studentCode + '.' + $dnsZone
  $studentSubnetName          = $studentCode + "subnet"
  $virtualNetworkName         = $studentCode + "vnet"
  $virtualNetworkAddressRange = "10.0.0.0/16"
  $publicIpName               = $studentCode + "-pip"
  $localAdminUsername         = "localadmin"
  $studentAdminUsername       = "studentadmin"
  $storageAccountName         = $studentCode + "storage"    # Lowercase required
  $URI                        = 'https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/azuredeploy.json'
  $artifactsLocation          = "https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/"
  $networkSecurityGroup       = "evil.training-nsg-" + $region
  $subscriptionId             = (Get-AzureRmContext).Subscription.SubscriptionId
  $windowsImagePublisher       = "MicrosoftWindowsServer"
  $windowsImageOffer           = "WindowsServer"
  $windowsImageSku             = "2012-R2-Datacenter"
  $filesUrl                   = "https://eviltraining.blob.core.windows.net/files/"

  # DC Variables
  $adAdminUserName            = "EvilAdmin"
  $domainName                 = "ad." + $dnsZone
  $adVMName                   = "dc01"
  $adNicIPAddress             = "10.0.0.4"
  $adVmSize                   = "Basic_A1"

  # Client Vars
  $clientVMName               = "home"
  $clientNicIpAddress         = "10.0.0.10"
  $clientVMSize               = "Basic_A2"
  $clientOU                   = "OU=Computers,OU=Class,DC=ad,DC=evil,DC=training"


  # Server Vars
  $serverVMName               = "server"
  $serverNicIpAddress         = "10.0.0.11"
  $serverVMSize               = "Basic_A1"
  $serverOU                   = "OU=Servers,OU=Class,DC=ad,DC=evil,DC=training"

  # Linux Vars
  $linuxVMName                = "linux"
  $linuxNicIpAddress          = "10.0.0.12"
  $linuxVMSize                = "Basic_A2"
  $linuxImagePublisher        = "Canonical"
  $linuxImageOffer            = "UbuntuServer"
  $linuxImageSku              = "16.04.0-LTS"

  # Create the new resource group. Runs quickly.
  try {
    Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
  }
  catch {
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
  }

  # Parameters for the template and configuration
  $MyParams = @{
    artifactsLocation           = $artifactsLocation
    studentSubnetName           = $studentSubnetName
    virtualNetworkName          = $virtualNetworkName
    virtualNetworkAddressRange  = $virtualNetworkAddressRange
    publicIpName                = $publicIpName
    localAdminUsername          = $localAdminUsername
    studentAdminUsername        = $studentAdminUsername
    studentPassword             = $studentPassword
    storageAccountName          = $storageAccountName
    networkSecurityGroup        = $networkSecurityGroup
    masterResourceGroup         = $masterResourceGroup
    subscriptionId              = $subscriptionId
    windowsImagePublisher       = $windowsImagePublisher
    windowsImageOffer           = $windowsImageOffer
    windowsImageSku             = $windowsImageSku
    BackupExecPassword          = $BackupExecPassword
    adAdminUsername             = $adAdminUserName
    domainName                  = $domainName
	  filesUrl                    = $filesUrl
    adVMName                    = $adVMName
    adNicIpAddress              = $adNicIPaddress
    adVMSize                    = $adVMSize
    clientVMName                = $clientVMName
    clientNicIpAddress          = $clientNicIPaddress
    clientVMSize                = $clientVMSize
    clientOU                    = $clientOU
    serverVMName                = $serverVMName
    serverNicIpAddress          = $serverNicIPaddress
    serverVMSize                = $serverVMSize
    serverOU                    = $serverOU
    linuxVMName                 = $linuxVMName
    linuxNicIpAddress           = $linuxNicIPaddress
    linuxVMSize                 = $linuxVMSize
    linuxImagePublisher         = $linuxImagePublisher
    linuxImageOffer             = $linuxImageOffer
    linuxImageSku               = $linuxImageSku
  }



  if ($Test) {
    $SplatParams = @{
      TemplateUri                 = $URI 
      ResourceGroupName           = $resourceGroupName 
      TemplateParameterObject     = $MyParams
    }
    Test-AzureRmResourceGroupDeployment @SplatParams -Verbose
  }
  else {
    # Splat the parameters on New-AzureRmResourceGroupDeployment  
    $SplatParams = @{
      TemplateUri                 = $URI 
      ResourceGroupName           = $resourceGroupName 
      TemplateParameterObject     = $MyParams
      Name                        = $studentCode + "-template"
    }
    try {
      New-AzureRmResourceGroupDeployment @SplatParams -Verbose -ErrorAction Stop 
      $deployed = $true
    }
    catch {
      Write-Error "New-AzureRmResourceGroupDeployment failed."
      Write-Output "Error Message:"
      Write-Output $_.Exception.Message
      Write-Output $_.Exception.ItemName
      $deployed = $false
    }
    
    $ipInfo = ( 
      @{
        "publicIpName" = $publicIpName
        "vmName" = $studentCode
      }
    )

    if ($deployed) {
      forEach ($item in $ipInfo) {
        $pip = Get-AzureRmPublicIpAddress -Name $item.publicIpName -ResourceGroupName $resourceGroupName
        $record = (New-AzureRmDnsRecordConfig -IPv4Address $pip.IpAddress)
        $rs = New-AzureRmDnsRecordSet -Name $item.vmName -RecordType "A" -ZoneName $dnsZone -ResourceGroupName $masterResourceGroup -Ttl 10 -DnsRecords $record
      }
    }
  }
}