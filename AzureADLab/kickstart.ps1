#break

# Shout out to @brwilkinson for assistance with some of this.


# Install the Azure Resource Manager modules from PowerShell Gallery
# Takes a while to install 28 modules
# Install-Module AzureRM -Force -Verbose
# Install-AzureRM

# Install the Azure Service Management module from PowerShell Gallery
# Install-Module Azure -Force -Verbose

# Import AzureRM modules for the given version manifest in the AzureRM module
# Import-AzureRM -Verbose

# Import Azure Service Management module
Import-Module Azure
Import-Module AzureRM

# Authenticate to your Azure account
# Login-AzureRmAccount
# Import-AzurePublishSettingsFile C:\Users\jared\Documents\jhaight-azure-credentials.publishsettings

function Get-RandomString ($length) {
  $set    = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
  $result = ""
  for ($x = 0; $x -lt $Length; $x++) {
    $result += $set | Get-Random
  }
  return $result
}

$URI  = 'https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/azuredeploy.json'
$location  = 'eastus2'
$resourceGroupName    = 'evil.training'
$studentCode = "a" + (Get-RandomString 6)
$adminUserName = "EvilAdmin"
$adminPasswordPlainText = "Beak-Today#Favor#Manufacture&0s"
$adminPassword = $secpasswd = ConvertTo-SecureString $adminPasswordPlainText -AsPlainText -Force
$domainName = "ad.evil.training"
$dnsPrefix = $studentCode
$storageAccountName = $studentCode+"storage"    # Lowercase required
$adVMName = $studentCode+"-dc01"
$adAvailabilitySetName = $studentCode+"AvailSet"
$adNicName = $studentCode + "nic"
$adNicIPAddress = "10.0.0.4"
$adSubnetName = $studentCode+"subnet"
$adSubnetAddressPrefix = 
$virtualNetworkName = $studentCode+"vnet"
$virtualNetworkAddressRange = "10.0.0.0/16"
$publicIPAddressName = $studentCode+"pip"

# Check that the public dns $addnsName is available
try {
  if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $location)
  { 
    'Available' 
  } 
  else 
  { 
    'Taken. addnsName must be globally unique.' 
    break
  }
}
catch {
  Login-AzureRmAccount
  if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $location)
  { 
    'Available' 
  } 
  else 
  { 
    'Taken. addnsName must be globally unique.' 
    break
  }
}

# Create the new resource group. Runs quickly.
try {
  Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
}
catch {
  New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}

# Parameters for the template and configuration
$MyParams = @{
  location              = 'East US'
  adminUsername         = $adminUserName
  adminPassword         = $adminPassword
  domainName            = $domainName
  dnsPrefix             = $dnsPrefix
  virtualNetworkName    = $virtualNetworkName
  storageAccountName    = $storageAccountName
  adNicName             = $adNicName
  adVMName              = $adVMName
  adSubnetName          = $adSubnetName
  publicIPAddressName   = $publicIPAddressName
  adAvailabilitySetname = $adAvailabilitySetName
  virtualNetworkAddressRange  = $virtualNetworkAddressRange
  adSubnetAddressPrefix = $adSubnetAddressPrefix
}

# Splat the parameters on New-AzureRmResourceGroupDeployment  
$SplatParams = @{
  TemplateUri             = $URI 
  ResourceGroupName       = $resourceGroupName 
  TemplateParameterObject = $MyParams
  Name                    = 'EVILTraining'
}

# This takes ~30 minutes
# One prompt for the domain admin password
New-AzureRmResourceGroupDeployment @SplatParams -Verbose

# Find the VM IP and FQDN
$PublicAddress = (Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName)[0]
$IP   = $PublicAddress.IpAddress
$FQDN = $PublicAddress.DnsSettings.Fqdn

# RDP either way
# Start-Process -FilePath mstsc.exe -ArgumentList "/v:$FQDN"
# Start-Process -FilePath mstsc.exe -ArgumentList "/v:$IP"

# Login as:  alpineskihouse\adadministrator
# Use the password you supplied at the beginning of the build.

# Explore the Active Directory domain:
#  Recycle bin enabled
#  Admin tools installed
#  Five new OU structures
#  Users and populated groups within the OU structures
#  Users root container has test users and populated test groups

# Delete the entire resource group when finished
# Remove-AzureRmResourceGroup -Name $resourceGroupName -Force -Verbose
