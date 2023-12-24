function Load-Resources {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [hashtable]$config = (Coalesce (Peek-Config), @{})
    )
    process {
        if (-not $config.resources) { return $config }

        $verbosity = $config.attributes.pwshake_verbosity
        try {
            # Write-Host -ForegroundColor DarkMagenta "$(Peek-Context | f-ctj)"
            if ((Peek-Verbosity) -gt [PWSHAKE.VerbosityLevel]((Peek-Options).resources_verbosity)) {
                $config.attributes.pwshake_verbosity = (Peek-Options).resources_verbosity
            }
            'PWSHAKE resources:' | f-log-lvl -level (Peek-Options).resources_verbosity
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
