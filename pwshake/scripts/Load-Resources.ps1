function Load-Resources {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [hashtable]$config = (Coalesce (Peek-Config), @{})
    )
    process {
        if (-not $config.resources) { return $config }

        $verbosity = $config.attributes.pwshake_verbosity
        $caption = "pwshake resources:"
        try {
            $config.attributes.pwshake_verbosity = 'Minimal'
            $caption | f-teamcity-o | Log-Minimal
            foreach ($step in $config.resources) {
                $step | Invoke-Step
            }
        }
        finally {
            $config.attributes.pwshake_verbosity = $verbosity
            $caption | f-teamcity-c | Log-Minimal
        }

        return $config
    }
}
