function Load-Resources {
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [hashtable]$config = (Peek-Config)
  )
  process {
    if (-not $config.resources) { return $config }

    $verbosity = $config.attributes.pwshake_verbosity
    try {
      if ((Peek-Verbosity) -gt [VerbosityLevel]((Peek-Options).resources_verbosity)) {
        $config.attributes.pwshake_verbosity = (Peek-Options).resources_verbosity
      }
      'pwshake resources:' | f-log-lvl -level (Peek-Options).resources_verbosity
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
