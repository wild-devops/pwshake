function Load-Resources {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  process {
    [hashtable]$config = ${@context}.config
    
    if (-not $config.resources) {
      return &${@next}(@{config=$config})
    }

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

    return &${@next}(@{config=$config})
  }
}
