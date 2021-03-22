function Load-Resources {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [hashtable]$config = (Coalesce (Peek-Config), @{})
    )
    process {
        if (-not $config.resources) { return $config }

        $verbosity = $config.attributes.pwshake_verbosity
        try {
            if ((Peek-Verbosity) -gt [PWSHAKE.VerbosityLevel](${global:pwshake-context}.options.resources_verbosity)) {
                $config.attributes.pwshake_verbosity = ${global:pwshake-context}.options.resources_verbosity
            }
            'PWSHAKE resources:' | f-log-lvl -level ${global:pwshake-context}.options.resources_verbosity
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
