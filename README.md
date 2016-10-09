##What is this?
This is a modification of the GitHub AzureRM repo template for a single DC deployment.
This version uses DSC with a configuration data file to deploy the domain and populate
sample data for an instant AD test lab.

##How do I do it?
Download CallingScript.ps1 to your local machine.
Modify the string naming parameters and run the code.
In 30 minutes you will have a populated AD test lab.

Or, download all these files. Tweak the DSC configuration, DSC configuration data, and azuredeploy.json to your own needs. Then host them on your own GitHub or Azure storage account.

##Prerequisites
- An Azure subscription (MSDN, trial, etc.)
- WMF 5.0 (or WMF 4.0 with PowerShellGet installed)

##Deploy On Azure
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FGoateePFE%2FAzureRM%2Fmaster%2Factive-directory-new-domain-with-data%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

##Contact
Ashley McGlone, Microsoft Premier Field Engineer

http://aka.ms/GoateePFE

March 2016

##LEGAL DISCLAIMER
This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys’ fees, that arise or result
from the use or distribution of the Sample Code.
 
This posting is provided "AS IS" with no warranties, and confers no rights. Use
of included script samples are subject to the terms specified
at http://www.microsoft.com/info/cpyright.htm.
 
