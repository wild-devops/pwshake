function Interpolate-Evals {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$step,

    [Parameter(Position = 1, Mandatory = $false)]
    [regex]$regex = '\$\[(?<key>.*?)\[(?<eval>.*?)\]\]',

    [Parameter(Position = 2, Mandatory = $false)]
    [string]$groupKey = 'eval',

    [Parameter(Position = 3, Mandatory = $false)]
    [hashtable]$config = (Peek-Config),

    [Parameter(Position = 4, Mandatory = $false)]
    [string]$template_key = $null
  )
  process {
    $ErrorActionPreference = "Stop"
    "Interpolate-Evals:In:$(@{'$_'=$_;'$template_key'="$template_key"} | cty)" | f-log-dbg

    $context_tmp = $step['$context']
    if (-not $template_key) {
      $template_key = $context_tmp.template_key
    }

    try {
      if ($template_key) {
        New-Variable -Name $template_key -Value $step -Force
        "Interpolate-Evals:$(@{('$'+$template_key)=(iex "$('${'+$template_key+'}')")} | cty)" | f-log-dbg
      }
      if ($context_tmp) {
        $step['$context'] = $null
      }

      $json = $step | f-ctj
      "Interpolate-Evals:In:`$json = $json" | f-log-dbg
      $counter = 0
      do {
        foreach ($match in $regex.Matches($json)) {
          $eval = $match.Groups[$groupKey].Value
          $key = $match.Groups['key'].Value
          $subst = $match.Groups[0].Value
          "Interpolate-Evals:Groups:`n$(@{subst=$subst;eval=$eval;key=$key} | cty))" | f-log-dbg
          if (($key) -and ($step.$($key) -is [string]) -and ($regex.Match($step.$($key)).Success)) {
            # it might be evaluated later
            continue;
          }
          $value = Invoke-Expression (ConvertFrom-Json "`"$eval`"")
          "Interpolate-Evals:Eval:$(@{'$value'=$value} | cty)" | f-log-dbg
          if ($value -isnot [string]) {
            # assign complex values via json, the trick with ,@(...) is to pass an array as itself into the pipeline
            $value = ,@($value) | f-ctj
            $json = $json.Replace("`"$subst`"", $value) # <<< it migth be former string
          } else {
            $value = $value | f-escape-json
          }
          $json = $json.Replace($subst, $value)
          "Interpolate-Evals:Replace:`$value = $value" | f-log-dbg
          "Interpolate-Evals:Replace:`$json = $json" | f-log-dbg
        }

        if ($counter++ -ge (Peek-Options).max_depth) {
          throw "Circular reference detected for evaluations: $($regex.Matches($json) | Sort-Object -Property Value)"
        }

        $step = $_ = $json | ConvertFrom-Yaml
        if ($template_key) {
          Set-Variable -Name $template_key -Value $step -Force
        }
        $json = $step | f-ctj
      } while ($regex.Match($json).Success)
    }
    finally {
      if ($context_tmp) { $step['$context'] = $context_tmp }
    }

    "Interpolate-Evals:Out:$(@{'$step'=$step} | cty)" | f-log-dbg
    return $step
  }
}
