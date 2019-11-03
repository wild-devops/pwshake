function Load-Resources {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$config
    )
    process {
        foreach ($step in $config.resources) {
            Invoke-Step $config $step
        }

        return $config
    }
}