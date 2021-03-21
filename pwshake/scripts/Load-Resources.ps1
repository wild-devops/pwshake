function Load-Resources {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [hashtable]$config = (Coalesce (Peek-Config), @{})
    )
    process {
        if (-not $config.resources) { return $config }

        $verbosity = $config.attributes.pwshake_verbosity
        $caption = "PWSHAKE resources:"
        try {
            $config.attributes.pwshake_verbosity = ${global:pwshake-context}.options.resources_verbosity
            $caption | Log-Minimal
            foreach ($step in $config.resources) {
                $step | Invoke-Step
            }
        }
        finally {
            $config.attributes.pwshake_verbosity = $verbosity
        }

        return $config
    }
}
