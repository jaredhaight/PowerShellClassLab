# xTimeZone

The **xTimeZone** module contains the **xTimeZone** DSC resource for setting the
time zone on a machine.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/7m4cwgkr5x4igpck/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xTimeZone/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/xTimeZone/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xTimeZone/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/7m4cwgkr5x4igpck/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xTimeZone/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/xTimeZone/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xTimeZone/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

### xTimeZone Resource

The resource will use the `Get-TimeZone` cmdlet to get the current
time zone. If `Get-TimeZone` is not available them CIM will be used to retrieve
the current time zone. To update the time zone, .NET reflection will be used to
update the time zone if required. If .NET reflection is not supported on the node
(in the case of Nano Server) then tzutil.exe will be used to set the time zone.

* **TimeZone**: Specifies the time zone. To discover all valid time zones for
  this property, use this PowerShell command: `[System.TimeZoneInfo]::GetSystemTimeZones().Id`.
* **IsSingleInstance**: Specifies if the resource is a single instance, the value
   must be 'Yes'.

### xTimeZone Examples

* [Set the time zone of the computer](/Examples/Resources/xTimeZone/1-SetTimeZone.ps1)

## Versions

### Unreleased

### 1.7.0.0

* Added resource helper module.
* Changed resource file names to include MSFT_*.
* Added MSFT_ to MOF file classname.
* Change examples to meet HQRM standards and optin to Example validation
  tests.
* Replaced examples in README.MD to links to Example files.
* Added the VS Code PowerShell extension formatting settings that cause PowerShell
  files to be formatted as per the DSC Resource kit style guidelines.
* Opted into Common Tests 'Validate Module Files' and 'Validate Script Files'.
* Converted files with UTF8 with BOM over to UTF8.
* Updated Year to 2017 in License and Manifest.
* Added .github support files:
  * CONTRIBUTING.md
  * ISSUE_TEMPLATE.md
  * PULL_REQUEST_TEMPLATE.md
* Resolved all PSScriptAnalyzer warnings and style guide warnings.

### 1.6.0.0

* Add support for Nano Server and WMF5.1 via Get-TimeZone/Set-TimeZone cmdlets.
* Minor changes to bring make resource ready for HQRM.
* Renamed and reworked functions in TimezoneHelper.psm1 to prevent conflicts with
  new built-in WMF5.1 Timezone Cmdlets.
* Fixed localization so that failback to en-US if culture specific language files
  not available.
* Moved code to init C# type into Set-TimeZoneUsingDotNet functions
* Renamed internal Timezone parameters to TimezoneId to more clearly represent value
* Converted AppVeyor.yml to pull Pester from PSGallery instead of Chocolatey
* Changed AppVeyor.yml to use default image
* Add Test-Command function to TimezoneHelper.psm1 for determining if a cmdlet exists.

### 1.5.0.0

* Fixed localization problem with DSC configuration Test/Get

### 1.4.0.0

* xTimeZone: Unit tests updated to use standard test template.
             Added Integration tests.
             Resource code updated to match style guidelines.
             Get-TargetResource returns IsSingleInstance value.
             Moved Get-TimeZone and Set-TimeZone to TimezoneHelper.psm1
             Added unit tests for TimezoneHelper.psm1
             Converted Get-TimeZone to use CIM cmdlets.
             Added support for Set-TimeZone to use .NET reflection if possible.
             Added message localization support.
             Changed Integration tests so that a complete test occurs if the
             System time is already set to 'Pacific Standard Time'.
* Copied SetTimeZone.ps1 example into Readme.md.
* AppVeyor build machine set to WMF5.

### 1.3.0.0

* Updated tests: now we are deploying xTimeZone instead of overwriting PSModulePath
  to make tests pass on local machine
* Updated validation attribute of IsSingleInstance parameter to match *.schema.mof

### 1.2.0.0

* Modified schema to follow best practices for singleton resources (changed
  xTimeZone key to IsSingleInstance)

### 1.1.0.0

* Added tests

### 1.0.0.0

* Initial release with the following resource:
  * xTimeZone
