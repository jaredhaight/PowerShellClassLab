<#
    .EXAMPLE
        This example sets the current time zone on the node
        to 'Tonga Standard Time'.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xTimeZone

    Node $NodeName
    {
        xTimeZone TimeZoneExample
        {
            IsSingleInstance = 'Yes'
            TimeZone         = 'Tonga Standard Time'
        }
    }
}
