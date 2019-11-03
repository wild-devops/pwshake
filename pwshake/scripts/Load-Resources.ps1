function Load-Resources {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$config
    )
    process {
        $verbosity = $config.attributes.pwshake_verbosity
        try {
            $config.attributes.pwshake_verbosity = "Error"
            foreach ($step in $config.resources) {
                Invoke-Step $config $step
            }
        } finally {
            $config.attributes.pwshake_verbosity = $verbosity
        }

        return $config
    }
}