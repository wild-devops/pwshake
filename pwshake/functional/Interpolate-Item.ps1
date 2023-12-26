function Interpolate-Item {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [object]$item,

    [Parameter(Mandatory = $false)]
    [hashtable]$step = @{},

    [Parameter(Mandatory = $false)]
    [hashtable]$config = (Peek-Config),

    [Parameter(Mandatory = $false)]
    [object[]]$rules = @(@{'\[\[\$\((?<eval>.*?)\)\]\]' = '' },
      @{'\[\[\.(?<eval>.*?)\]\]' = '$context.' })
  )
  process {
    ":In:" | f-log-dbg '$_', '$step'
    if (-not $item) {
      return $step
    }

    $context_tmp = $step['$context']
    if ($context_tmp) { $step.Remove('$context') }

    if (($item.GetType() -match 'HashtableEnumerator') `
        -or ($item -is [Collections.DictionaryEntry])) {
      $item = $item | ForEach-Object { @{Key = $_.Key; Value = $_.Value } }
    }

    $context = $step
    if ($item -is [hashtable]) {
      $context = Merge-Hashtables $step $item
    }
    $context = $context | Interpolate-Evals
    ":Eval-Context:$(@{'$context'=$context} | ConvertTo-Yaml)" | f-log-dbg

    try {
      $json = $context | ConvertTo-Json -Depth 99
      ":Merge:`$json = $json" | f-log-dbg
      $counter = 0
      foreach ($regex in $rules.Keys) {
        while ($json -match $regex) {
          ":$(@{'$matches'=$matches}  | ConvertTo-Yaml)" | f-log-dbg
          $subst = $matches.0
          $eval = $matches.eval
          if (-not $eval) {
            if ($item -is [hashtable]) {
              $value = $context | f-subtract -s $step
            }
            else {
              $value = $item
            }
          }
          else {
            $eval = ConvertFrom-Json "`"$($rules.$($regex))$eval`""
            $value = Invoke-Expression $eval
          }
          if ($value -isnot [string]) {
            # assign complex values via json
            $value = $value | ConvertTo-Json -Depth 99
            ":Out:ConvertTo-Json:`$value = $value" | f-log-dbg
            # it might be former string, so:
            $json = $json.Replace("`"$subst`"", $value)
          }
          else {
            $value = $value | f-escape-json
          }
          ":Replace:In:`n$(@{subst=`"$subst`";eval=`"$eval`";value=`"$value`"} | ConvertTo-Yaml)" | f-log-dbg
          $json = $json.Replace($subst, $value)
          ":Replace:Out:$(@{'$json'=`"$json`"} | ConvertTo-Yaml)" | f-log-dbg

          if ($counter++ -ge (Peek-Options).max_depth) {
            throw "Circular reference detected for evaluations: $($regex.Matches($json) | Sort-Object -Property Value)"
          }

          $context = $json | ConvertFrom-Yaml
        }
      }
      ":Loop-Out:" | f-log-dbg '$context'
    }
    finally {
      if ($context_tmp) { $context['$context'] = $context_tmp }
      if ($step.Keys.Count) {
        $item.Keys | f-null | ForEach-Object { $context.Remove($_) }
      }
    }

    ":Out:" | f-log-dbg '$context'
    return $context
  }
}
