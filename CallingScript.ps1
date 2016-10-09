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
Import-AzurePublishSettingsFile C:\Users\jared\Documents\jhaight-azure-credentials.publishsettings

function Get-RandomString ($length) {
  $set    = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
  $result = ""
  for ($x = 0; $x -lt $Length; $x++) {
    $result += $set | Get-Random
  }
  return $result
}

$URI       = 'https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/azuredeploy.json'
$Location  = 'eastus2'
$rgname    = 'evil.training'
$studentCode = "a" + (Get-RandomString 6)
$saname    = $studentCode+"storage"    # Lowercase required
$addnsName = $studentCode+"addns"     # Lowercase required

# Check that the public dns $addnsName is available
try {
  if (Test-AzureRmDnsAvailability -DomainNameLabel $addnsName -Location $Location)
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
  if (Test-AzureRmDnsAvailability -DomainNameLabel $addnsName -Location $Location)
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
  Get-AzureRmResourceGroup -Name $rgname -Location $Location -ErrorAction Stop
}
catch {
  New-AzureRmResourceGroup -Name $rgname -Location $Location
}

# Parameters for the template and configuration
$MyParams = @{
  newStorageAccountName = $saname
  location              = 'East US'
  domainName            = 'ad.evil.training'
  studentCode           = $studentCode
  addnsName             = $addnsName
}

# Splat the parameters on New-AzureRmResourceGroupDeployment  
$SplatParams = @{
  TemplateUri             = $URI 
  ResourceGroupName       = $rgname 
  TemplateParameterObject = $MyParams
  Name                    = 'EVILTraining'
}

# This takes ~30 minutes
# One prompt for the domain admin password
New-AzureRmResourceGroupDeployment @SplatParams -Verbose

# Find the VM IP and FQDN
$PublicAddress = (Get-AzureRmPublicIpAddress -ResourceGroupName $rgname)[0]
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
# Remove-AzureRmResourceGroup -Name $rgname -Force -Verbose
