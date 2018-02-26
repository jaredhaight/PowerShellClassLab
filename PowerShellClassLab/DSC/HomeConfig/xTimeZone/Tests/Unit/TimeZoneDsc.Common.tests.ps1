$script:ModuleName = 'TimeZoneDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

#region Pester Tests
InModuleScope $script:ModuleName {
    Describe 'Get-TimeZoneId' {
        Context '"Get-TimeZone" not available and current timezone is set to "Pacific Standard Time"' {
            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                @{
                    StandardName = 'Pacific Standard Time'
                }
            }

            It 'Returns "Pacific Standard Time"' {
                Get-TimeZoneId | Should Be 'Pacific Standard Time'
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Get-TimeZone'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
            }
        }

        Context '"Get-TimeZone" not available and current timezone is set to "Russia TZ 11 Standard Time"' {
            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                @{
                    StandardName = 'Russia TZ 11 Standard Time'
                }
            }

            It 'Returns "Russia Time Zone 11"' {
                Get-TimeZoneId | Should Be 'Russia Time Zone 11'
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Get-TimeZone'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
            }
        }

        Context '"Get-TimeZone" available and current timezone is set to "Pacific Standard Time"' {
            function Get-TimeZone
            {
            }

            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone'
            } -MockWith {
                'Get-TimeZone'
            }

            Mock -CommandName Get-TimeZone -MockWith {
                @{
                    StandardName = 'Pacific Standard Time'
                }
            }

            It 'Returns "Pacific Standard Time"' {
                Get-TimeZoneId | Should Be 'Pacific Standard Time'
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Get-TimeZone'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName Get-TimeZone -Exactly -Times 1
            }
        }
    }

    Describe 'Test-TimezoneId' {
        Mock Get-TimeZoneId -MockWith {
            'Russia Time Zone 11'
        }

        Context 'current timezone matches desired timezone' {
            It 'Should return $true' {
                Test-TimezoneId -TimeZoneId 'Russia Time Zone 11' | Should Be $true
            }
        }

        Context 'current timezone does not match desired timezone' {
            It 'Should return $false' {
                Test-TimezoneId -TimeZoneId 'GMT Standard Time' | Should Be $false
            }
        }
    }

    Describe 'Set-TimeZoneId' {
        Context '"Set-TimeZone" and "Add-Type" is not available, Tzutil Returns 0' {
            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Add-Type'
            }

            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Set-TimeZone'
            }

            Mock -CommandName 'TzUtil.exe' -MockWith {
                $global:LASTEXITCODE = 0
                return 'OK'
            }

            Mock -CommandName Add-Type

            It 'Should not throw an exception' {
                { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should Not Throw
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Add-Type'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Set-TimeZone'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName TzUtil.exe -Exactly -Times 1
                Assert-MockCalled -CommandName Add-Type -Exactly -Times 0
            }
        }

        Context '"Set-TimeZone" is not available but "Add-Type" is available' {
            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Add-Type'
            } -MockWith {
                'Add-Type'
            }

            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Set-TimeZone'
            }

            Mock -CommandName 'TzUtil.exe' -MockWith {
                $global:LASTEXITCODE = 0
                return 'OK'
            }

            Mock -CommandName Add-Type
            Mock -CommandName Set-TimeZoneUsingDotNet

            It 'Should not throw an exception' {
                { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should Not Throw
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Add-Type'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Set-TimeZone'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName TzUtil.exe -Exactly -Times 0
                Assert-MockCalled -CommandName Add-Type -Exactly -Times 0
                Assert-MockCalled -CommandName Set-TimeZoneUsingDotNet -Exactly -Times 1
            }
        }

        Context '"Set-TimeZone" is available' {
            function Set-TimeZone
            {
                param
                (
                    [System.String]
                    $id
                )
            }

            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Add-Type'
            }

            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Set-TimeZone'
            } -MockWith {
                'Set-TimeZone'
            }

            Mock -CommandName Set-TimeZone

            It 'Should not throw an exception' {
                { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should Not Throw
            }

            It 'Should call expected mocks' {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Add-Type'
                } -Exactly -Times 0

                Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Set-TimeZone'
                } -Exactly -Times 1

                Assert-MockCalled -CommandName Set-TimeZone -Exactly -Times 1
            }
        }
    }

    Describe 'Test-Command' {
        Context 'Command "Get-TimeZone" exists' {
            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone' `
                    -and $Module -eq 'Microsoft.PowerShell.Management'
            } -MockWith {
                @{
                    Name = 'Get-TimeZone'
                }
            }

            It 'Should return $true' {
                Test-Command `
                    -Name 'Get-TimeZone' `
                    -Module 'Microsoft.PowerShell.Management' | Should Be $true
            }

            It 'Should call expected mocks' {
                Assert-MockCalled `
                    -CommandName Get-Command `
                    -ParameterFilter {
                    $Name -eq 'Get-TimeZone' `
                        -and $Module -eq 'Microsoft.PowerShell.Management'
                } -Exactly -Times 1
            }
        }

        Context 'Command "Get-TimeZone" does not exist' {
            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone' `
                    -and $Module -eq 'Microsoft.PowerShell.Management'
            }

            It 'Should return $false' {
                Test-Command `
                    -Name 'Get-TimeZone' `
                    -Module 'Microsoft.PowerShell.Management' | Should Be $false
            }

            It 'Should call expected mocks' {
                Assert-MockCalled `
                    -CommandName Get-Command `
                    -ParameterFilter {
                    $Name -eq 'Get-TimeZone' `
                        -and $Module -eq 'Microsoft.PowerShell.Management'
                } -Exactly -Times 1
            }
        }
    }
}
