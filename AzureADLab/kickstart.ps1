param (
  [string]$adAdminPassword,
  [string]$studentAdminPassword
)

# Import Azure Service Management module
Import-Module Azure
Import-Module AzureRM

function Get-RandomString ($length) {
  $set    = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
  $result = ""
  for ($x = 0; $x -lt $Length; $x++) {
    $result += $set | Get-Random
  }
  return $result
}

# Common Variables
$location                   = 'eastus2'
$locationName               = "East US"
$studentCode                = "a" + (Get-RandomString 6)
$resourceGroupName          = $studentCode + '.evil.training'
$studentSubnetName          = $studentCode + "subnet"
$studentSubnetAddressPrefix = "10.0.0.0/24"
$virtualNetworkName         = $studentCode + "vnet"
$virtualNetworkAddressRange = "10.0.0.0/16"
$studentAdminUsername       = "localAdmin"
$storageAccountName         = $studentCode + "storage"    # Lowercase required
$URI                        = 'https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/azuredeploy.json'
$artifactsLocation         = "https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/"

# DC Variables
$adAdminUserName            = "EvilAdmin"
$domainName                 = "ad.evil.training"
$adVMName                   = $studentCode + "-dc01"
$adNicIPAddress             = "10.0.0.4"
$adVmSize                   = "Basic_A1"
$adImagePublisher           = "MicrosoftWindowsServer"
$adImageOffer               = "WindowsServer"
$adImageSku                 = "2012-R2-Datacenter"

# Client Vars
$clientVMName               = $studentCode + "-home"
$clientNicIpAddress         = "10.0.0.10"
$clientVMSize               = "Basic_A2"
$clientImagePublisher       = "MicrosoftWindowsServer"
$clientImageOffer           = "WindowsServer"
$clientImageSku             = "2012-R2-Datacenter"

# Server Vars
$serverVMName               = $studentCode+"-srv"
$serverNicIpAddress         = "10.0.0.11"
$serverVMSize               = "Basic_A1"
$serverImagePublisher       = "MicrosoftWindowsServer"
$serverImageOffer           = "WindowsServer"
$serverImageSku             = "2012-R2-Datacenter"


# Linux Vars
$linuxVMName                = $studentCode+"-lnx"
$linuxNicIpAddress          = "10.0.0.12"
$linuxVMSize                = "Basic_A2"
$linuxImagePublisher        = "Canonical"
$linuxImageOffer            = "UbuntuServer"
$linuxImageSku              = "16.04.0-LTS"

# Check if logged in to Azure
Try {
  Get-AzureRMContext -ErrorAction Stop
}
Catch {
  Login-AzureRmAccount
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
  artifactsLocation          = $artifactsLocation
  studentSubnetName           = $studentSubnetName
  studentSubnetAddressPrefix  = $studentSubnetAddressPrefix
  virtualNetworkName          = $virtualNetworkName
  virtualNetworkAddressRange  = $virtualNetworkAddressRange
  studentAdminUsername        = $studentAdminUsername
  studentAdminPassword        = $studentAdminPassword
  storageAccountName          = $storageAccountName
  adAdminUsername             = $adAdminUserName
  adAdminPassword             = $adAdminPassword
  domainName                  = $domainName
  adVMName                    = $adVMName
  adNicIpAddress              = $adNicIPAddress
  adVMSize                    = $adVMSize
  adImagePublisher            = $adImagePublisher
  adImageOffer                = $adImageOffer
  adImageSku                  = $adImageSku
  clientVMName                = $clientVMName
  clientNicIpAddress          = $clientNicIPaddress
  clientVMSize                = $clientVMSize
  clientImagePublisher        = $clientImagePublisher
  clientImageOffer            = $clientImageOffer
  clientImageSku              = $clientImageSku
  serverVMName                = $serverVMName
  serverNicIpAddress          = $serverNicIPAddress
  serverVMSize                = $serverVMSize
  serverImagePublisher        = $serverImagePublisher
  serverImageOffer            = $serverImageOffer
  serverImageSku              = $serverImageSku
  linuxVMName                 = $linuxVMName
  linuxNicIpAddress           = $linuxNicIPAddress
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

# This takes ~30 minutes
# One prompt for the domain admin password
New-AzureRmResourceGroupDeployment @SplatParams -Verbose