configuration MSFT_xTimeZone_Config {
    Import-DscResource -ModuleName xTimeZone

    node localhost {
        xTimeZone Integration_Test {
            TimeZone         = $Node.TimeZone
            IsSingleInstance = $Node.IsSingleInstance
        }
    }
}
