## Azure AD lab
This is a set of Azure Resource Manager Templates that generates an Active Directory lab consisting of a Domain Controller, two Windows servers and a Linux server. I created this so that I could easily deploy AD Labs for students in my PowerShell classes, so it's geared toward spinning up multiple, identical labs. 

One of the Windows servers is intended to be used as "home" box, where students will do work while the other is intended to be an example server for the environment. The Linux box will be used to run [Metasploit](https://www.metasploit.com/) and [Empire](https://github.com/adaptivethreat/Empire) as part of class exercises.

## How it works
`New-PowerShellClassLab.ps1` provides a function called `New-PowerShellClassLab` which takes the following parameters:
* Credentials: Azure AD Credentials that have rights to create stuff. [This article](https://blogs.technet.microsoft.com/orchestrator/2016/06/06/how-to-setup-and-configure-microsoft-azure-automation-runbooks/) should get you pointed in the right direction.
* CSVSource: A file path pointed to a CSV file with the following fields:
    - Code: This code is used throughout the process to create unique names for assets. It needs to be an alphanumeric string that starts with a letter. Length doesn't matter, I use six to eight characters.
    - Password: This password will be used for all accounts in the lab.

The `New-PowerShellClassLab` function calls `Invoke-CreatePowerShellClassLab` which uses [Azure Resource Manager Templates](https://azure.microsoft.com/en-us/documentation/articles/resource-group-authoring-templates/) to create the Infrastructure. The are plenty of variables hard coded in the function which you may want to customize to your needs. Their purposes should be clear.

Each lab is created in it's own Resource Group, so for easy tear down a `Remove-AllAzureResourceGroups` script is provided.

## Prerequisites
* An Azure subscription (MSDN, trial, etc.)
* WMF 5.0 (or WMF 4.0 with PowerShellGet installed)
* Azure PowerShell Cmdlets
    - You can install these with `Install-Module Azure` and `Install-Module AzureRM`
* A Resource Group in Azure that contains the following resources which will be used across all labs:
    - DNSZone: This will be used to register public DNS entries for each Student VM. 
    - Network Security Group. This will be applied to all VMs, providing a centralized way to enforce Firewall rules.
* `Invoke-CreatePowerShellClassLab` uses the following variables which will need to be updated.
    - `$masterResourceGroup`: The Resource Group containing the DNS Zone and NSG.
    - `$dnsZone`: The name of the DNS Zone that Student DNS records will be created in.
    - `$networkSecurityGroup`: The name of the NSG that will be applied to all VMs

## Credits
The following resources were used to put this together:

* [GoateePFE's AzureRM repo](https://github.com/GoateePFE/AzureRM/tree/master/active-directory-new-domain-with-data)
* The following quick start Templates:
    - [Active Directory New Domain](https://github.com/GoateePFE/AzureRM/tree/master/active-directory-new-domain-with-data)
    - [101 VM Simple Linux](https://github.com/Azure/azure-quickstart-templates/tree/master/101-vm-simple-linux)
    