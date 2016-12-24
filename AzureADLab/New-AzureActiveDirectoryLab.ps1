workflow New-AzureActiveDirectoryLab {

  [CmdletBinding()]
  Param( 
    [Parameter(Mandatory=$True,Position=1)]
    [pscredential]$credentials,

    [Parameter(Mandatory=$True,Position=2)]
    [string]$csvSource
  ) 

  $studentData = Import-CSV $csvSource
  foreach -parallel -throttle 20 ($student in $studentData) {
     $studentAdminPassword = $student.password
     $studentCode = $student.code.toString()
     $studentNumber = $student.id
     $region = 'eastus2'
     
     if ($studentNumber % 2 -eq 0) {
       $region = 'westus2'
     }
     Write-Output "Sending $studentCode to $region"
     Invoke-CreateAzureActiveDirectoryLab -credentials $credentials -studentCode $studentCode -studentAdminPassword $studentAdminPassword -region $region -place $studentNumber -total $studentData.count 
   }
}

function Invoke-CreateAzureActiveDirectoryLab {
  
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True,Position=1)]
    [pscredential]$credentials,

    [Parameter(Mandatory=$True,Position=2)]
    [string]$studentCode,

    [Parameter(Mandatory=$True,Position=3)]
    [string]$studentAdminPassword,
    
    [string]$region="eastus2",
    [int]$place=1,
    [int]$total=1
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
  $studentSubnetAddressPrefix = "10.0.0.0/24"
  $virtualNetworkName         = $studentCode + "vnet"
  $virtualNetworkAddressRange = "10.0.0.0/16"
  $studentAdminUsername       = "localadmin"
  $storageAccountName         = $studentCode + "storage"    # Lowercase required
  $URI                        = 'https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/azuredeploy.json'
  $artifactsLocation          = "https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/"
  $networkSecurityGroup       = "evil.training-nsg-" + $region
  $subscriptionId             = (Get-AzureRmContext).Subscription.SubscriptionId
  $windowsImagePublisher       = "MicrosoftWindowsServer"
  $windowsImageOffer           = "WindowsServer"
  $windowsImageSku             = "2012-R2-Datacenter"

  # DC Variables
  $adAdminUserName            = "EvilAdmin"
  $domainName                 = "ad." + $dnsZone
  $adVMName                   = $studentCode + "-dc01"
  $adNicName                  = $adVMName + "-nic"
  $adNicIPAddress             = "10.0.0.4"
  $adVmSize                   = "Basic_A1"

  # Client Vars
  $clientVMName               = $studentCode + "-home"
  $clientNicName              = $clientVMName + "-nic"
  $clientNicIpAddress         = "10.0.0.10"
  $clientPublicIpName         = $clientVMName + "-pip"
  $clientVMSize               = "Basic_A2"


  # Server Vars
  $serverVMName               = $studentCode+"-srv"
  $serverNicName              = $serverVMName + "-nic"
  $serverNicIpAddress         = "10.0.0.11"
  $serverVMSize               = "Basic_A1"


  # Linux Vars
  $linuxVMName                = $studentCode+"-lnx"
  $linuxNicName               = $linuxVMName + "-nic"
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
    studentSubnetAddressPrefix  = $studentSubnetAddressPrefix
    virtualNetworkName          = $virtualNetworkName
    virtualNetworkAddressRange  = $virtualNetworkAddressRange
    studentAdminUsername        = $studentAdminUsername
    studentAdminPassword        = $studentAdminPassword
    storageAccountName          = $storageAccountName
    networkSecurityGroup        = $networkSecurityGroup
    masterResourceGroup         = $masterResourceGroup
    subscriptionId              = $subscriptionId
    adAdminUsername             = $adAdminUserName
    domainName                  = $domainName
    adVMName                    = $adVMName
    adNicName                   = $adNicName
    adNicIpAddress              = $adNicIPaddress
    adVMSize                    = $adVMSize
    adImagePublisher            = $adImagePublisher
    adImageOffer                = $adImageOffer
    adImageSku                  = $adImageSku
    clientVMName                = $clientVMName
    clientNicName               = $clientNicName
    clientNicIpAddress          = $clientNicIPaddress
    clientPublicIpName          = $clientPublicIpName
    clientVMSize                = $clientVMSize
    windowsImagePublisher       = $windowsImagePublisher
    windowsImageOffer           = $windowsImageOffer
    windowsImageSku             = $windowsImageSku
    serverVMName                = $serverVMName
    serverNicName               = $serverNicName
    serverNicIpAddress          = $serverNicIPaddress
    serverVMSize                = $serverVMSize
    serverImagePublisher        = $serverImagePublisher
    serverImageOffer            = $serverImageOffer
    serverImageSku              = $serverImageSku
    linuxVMName                 = $linuxVMName
    linuxNicName                = $linuxNicName
    linuxNicIpAddress           = $linuxNicIPaddress
    linuxVMSize                 = $linuxVMSize
    linuxImagePublisher         = $linuxImagePublisher
    linuxImageOffer             = $linuxImageOffer
    linuxImageSku               = $linuxImageSku
  }

  # Splat the parameters on New-AzureRmResourceGroupDeployment  
  $SplatParams = @{
    TemplateUri                 = $URI 
    ResourceGroupName           = $resourceGroupName 
    TemplateParameterObject     = $MyParams
    Name                        = $studentCode + "-template"
  }

  New-AzureRmResourceGroupDeployment @SplatParams -Verbose

  $ipInfo = ( 
    @{
      "publicIpName" = $clientPublicIpName
      "vmName" = $studentCode
    }
  )

  forEach ($item in $ipInfo) {
    $pip = Get-AzureRmPublicIpAddress -Name $item.publicIpName -ResourceGroupName $resourceGroupName
    $record = (New-AzureRmDnsRecordConfig -IPv4Address $pip.IpAddress)
    $rs = New-AzureRmDnsRecordSet -Name $item.vmName -RecordType "A" -ZoneName $dnsZone -ResourceGroupName $masterResourceGroup -Ttl 10 -DnsRecords $record
  }
}