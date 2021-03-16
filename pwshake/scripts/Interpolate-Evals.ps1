function Interpolate-Evals {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$step,

    [Parameter(Position = 1, Mandatory = $false)]
    [regex]$regex = '\$\[(?<key>.*?)\[(?<eval>.*?)\]\]',

    [Parameter(Position = 2, Mandatory = $false)]
    [string]$groupKey = 'eval',

    [Parameter(Position = 3, Mandatory = $false)]
    [hashtable]$config = (Coalesce (Peek-Config), @{}),

    [Parameter(Position = 4, Mandatory = $false)]
    [string]$template_key = $null
  )
  process {
    "Interpolate-Evals:In:$(@{'$_'=$_;'$template_key'="$template_key"} | ConvertTo-Yaml)" | f-dbg

    $context_tmp = $step['$context']
    if (-not $template_key) {
      $template_key = $context_tmp.template_key
    }

    try {
      if ($template_key) {
        New-Variable -Name $template_key -Value $step -Force
      }
      if ($context_tmp) {
        $step['$context'] = $null
      }

      $json = $step | f-ctj
      "Interpolate-Evals:In:`$json = $json" | f-dbg
      $counter = 0
      do {
        foreach ($match in $regex.Matches($json)) {
          $eval = $match.Groups[$groupKey].Value
          $key = $match.Groups['key'].Value
          $subst = $match.Groups[0].Value
          "Interpolate-Evals:Groups:`n$(@{subst=$subst;eval=$eval;key=$key} | ConvertTo-Yaml))" | f-dbg
          if (($key) -and ($step.$($key) -is [string]) -and ($regex.Match($step.$($key)).Success)) {
            # it might be evaluated later
            continue
          }
          $value = Invoke-Expression ("`"$eval`"" | ConvertFrom-Json)
          "Interpolate-Evals:Eval:$(@{'$value'=$value} | ConvertTo-Yaml)" | f-dbg
          if ($value -isnot [string]) {
            # assign complex values via json, the trick with ,@(...) is to pass an array as itself into the pipeline
            $value = ,@($value) | f-ctj
            $json = $json.Replace("`"$subst`"", $value) # <<< it migth be former string
          } else {
            $value = $value | f-escape-json
          }
          $json = $json.Replace($subst, $value)
          "Interpolate-Evals:Replace:`$value = $value" | f-dbg
          "Interpolate-Evals:Replace:`$json = $json" | f-dbg
        }

        if ($counter++ -ge ${global:pwshake-context}.options.max_depth) {
          throw "Circular reference detected for evaluations: $($regex.Matches($json) | Sort-Object -Property Value)"
        }

        $step = $json | ConvertFrom-Yaml
        if ($template_key) {
          Set-Variable -Name $template_key -Value $step -Force
        }
        $json = $step | f-ctj
      } while ($regex.Match($json).Success)
    }
    finally {
      if ($context_tmp) { $step['$context'] = $context_tmp }
    }

    "Interpolate-Evals:Out:$(@{'$step'=$step} | ConvertTo-Yaml)" | f-dbg
    return $step
  }
}
