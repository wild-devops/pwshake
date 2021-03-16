function Interpolate-Item {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [object]$item,

    [Parameter(Mandatory = $false)]
    [hashtable]$step = @{},

    [Parameter(Mandatory = $false)]
    [hashtable]$config = (Coalesce (Peek-Config), @{}),

    [Parameter(Mandatory = $false)]
    [object[]]$rules = @(@{'\[\[\$\((?<eval>.*?)\)\]\]'=''},
      @{'\[\[\.(?<eval>.*?)\]\]'='$context.'})
  )
  process {
    "Interpolate-Item:In:$(@{'$_'=$_} | ConvertTo-Yaml)" | f-dbg
    "Interpolate-Item:In:$(@{'$step'=$step} | ConvertTo-Yaml)" | f-dbg

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
    "Interpolate-Item:Build-Context:$(@{'$context'=$context} | ConvertTo-Yaml)" | f-dbg

    try {
      $json = $context | ConvertTo-Json -Depth 99
      "Interpolate-Item:Merge:`$json = $json" | f-dbg
      $counter = 0
      foreach ($regex in $rules.Keys) {
        while ($json -match $regex) {
          "Interpolate-Item:$(@{'$matches'=$matches}  | ConvertTo-Yaml)" | f-dbg
          $subst = $matches.0
          $eval = $matches.eval
          if (-not $eval) {
            if ($item -is [hashtable]){
              $value = $context | f-subtract -s $step
            } else {
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
            "Interpolate-Item:Out:ConvertTo-Json:`$value = $value" | f-dbg
            # it might be former string, so:
            $json = $json.Replace("`"$subst`"", $value)
          }
          else {
            $value = $value | f-escape-json
          }
          "Interpolate-Item:Replace:In:`n$(@{subst=`"$subst`";eval=`"$eval`";value=`"$value`"} | ConvertTo-Yaml)" | f-dbg
          $json = $json.Replace($subst, $value)
          "Interpolate-Item:Replace:Out:$(@{'$json'=`"$json`"} | ConvertTo-Yaml)" | f-dbg

          if ($counter++ -ge ${global:pwshake-context}.options.max_depth) {
            throw "Circular reference detected for evaluations: $($regex.Matches($json) | Sort-Object -Property Value)"
          }

          $context = $json | ConvertFrom-Yaml
        }
      }
      "Interpolate-Item:Loop-Out:$(@{'$context'=$context} | ConvertTo-Yaml)" | f-dbg
    }
    finally {
      if ($context_tmp) { $context['$context'] = $context_tmp }
      if ($step.Keys.Count) {
        $item.Keys | f-null | ForEach-Object { $context.Remove($_) }
      }
    }

    "Interpolate-Item:Out:$(@{'$context'=$context} | ConvertTo-Yaml)" | f-dbg
    return $context
  }
}
