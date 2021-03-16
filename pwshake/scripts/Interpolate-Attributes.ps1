function Interpolate-Attributes {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$config
)
  process {
      $json = $config | ConvertTo-Json -Depth 99 -Compress
      $regex = [regex]'{{(?<subst>(?:(?!{{).)+?)}}'
      $counter = 0
      "Interpolate-Attributes:In:$($counter):`$json:$json" | f-dbg

      do {
        foreach ($substitute in (Get-Matches $json $regex 'subst')) {
          "Interpolate-Attributes:$($counter):`$substitute:$substitute" | f-dbg
          if ($substitute -match '^\$\((?<eval>.*)\)$') {
            "Interpolate-Attributes:$($counter):`$eval:{$($matches.eval)}" | f-dbg
            $value = Invoke-Expression (ConvertFrom-Json "`"$($matches.eval)`"")
          } elseif ($substitute -match '^(?<filter>\$\S+):(?<input>.*)') {
            "Interpolate-Attributes:$($counter):`$filter:{$($matches.filter)}:`$input:{$($matches.input)}" | f-dbg
            $value = $matches.input | & "f-$($matches.filter)"
            "Interpolate-Attributes:$($counter):`$value:{$value}" | f-dbg
          } else {
            $value = Invoke-Expression "`$config.attributes.$substitute" -ErrorAction Stop
            if ($regex.Match($value).Success) {
                continue;
            }
          }
          $value = $value | f-null | ForEach-Object {(ConvertTo-Json $_ -Compress -Depth 99).Trim('"')}
          "Interpolate-Attributes:$($counter):`$value:{$value}" | f-dbg
          $json = $json.Replace("{{$substitute}}", "$value")
        }
        if ($counter++ -ge ${global:pwshake-context}.options.max_depth) {
          throw "Circular reference detected for substitutions: $($regex.Matches($json) | Sort-Object -Property Value)"
        }
        "Interpolate-Attributes:$($counter):`$json:`n$json" | f-dbg
        $config = ConvertFrom-Yaml $json
        $json = ConvertTo-Json $config -Depth 99 -Compress
      } while ($regex.Match($json).Success)

      return ConvertFrom-Yaml $json
  }
}
