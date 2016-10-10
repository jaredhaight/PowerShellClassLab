#Create variables
# Enter a new user name and password to use as the local administrator account for the remotely accessing the VM
$secpasswd = ConvertTo-SecureString “Beak-Today#Favor#Manufacture&0s” -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential (“adadministrator”, $secpasswd)

# Name of the storage account 
$storageAccName = "tempclone01sa"

# Name of the virtual machine
$vmName = "tmpclone01vm"

# Size of the virtual machine. See the VM sizes documentation for more information: https://azure.microsoft.com/documentation/articles/virtual-machines-windows-sizes/
$vmSize = "Standard_A2"

# Computer name for the VM
$computerName = "tempclone01"

# Name of the disk that holds the OS
$osDiskName = "tempclone01os"

# Assign a SKU name
# Valid values for -SkuName are: **Standard_LRS** - locally redundant storage, **Standard_ZRS** - zone redundant storage, **Standard_GRS** - geo redundant storage, **Standard_RAGRS** - read access geo redundant storage, **Premium_LRS** - premium locally redundant storage. 
$skuName = "Standard_LRS"

# Resource Group Name
$rgName = 'evil.training-master'

$imageURI = "https://wintemplatestorage.blob.core.windows.net/system/Microsoft.Compute/Images/templates/template-osDisk.c3c54120-6443-4fb2-90f5-06fbc4dbd532.vhd"

$locName = "eastus2"
$subnetName = "tmponesnet"
$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.1.0.0/24"

$vnetName = "tmpclone01-vnet"
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $locName -AddressPrefix "10.1.0.0/16" -Subnet $singleSubnet

$ipName = "tmpclone01-ip"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic

$nicName = "tempclone01-nic"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

# Create a new storage account for the VM
New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $storageAccName -Location $location -SkuName $skuName -Kind "Storage"

#Get the storage account where the uploaded image is stored
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $storageAccName

#Set the VM name and size
#Use "Get-Help New-AzureRmVMConfig" to know the available options for -VMsize
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize

#Set the Windows operating system configuration and add the NIC
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $computerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

#Create the OS disk URI
$osDiskUri = '{0}vhds/{1}-{2}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName

#Configure the OS disk to be created from the image (-CreateOption fromImage), and give the URL of the uploaded image VHD for the -SourceImageUri parameter
#You set this variable when you uploaded the VHD
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $imageURI -Windows

#Create the new VM
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm