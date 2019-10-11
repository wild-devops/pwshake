function Interpolate-Attributes {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$config
)    
  process {
      $ErrorActionPreference = "Stop"

      $yaml = $config | ConvertTo-Yaml
      $regex = [regex]"{{(?<subst>([^{{.*}}]|[.*])*?)}}"
      $counter = 0

      do {
        foreach ($substitute in (Get-Matches $yaml $regex 'subst')) {
          if ($substitute -match '^\$\((?<eval>.*?)\)$') {
            $eval = Get-Matches $substitute '^\$\((?<eval>.*?)\)$' 'eval'
            $value = Invoke-Expression $eval
            $yaml = $yaml.Replace("{{$substitute}}", "$value")
          } elseif ($substitute -match '^\$env:') {
            $value = Invoke-Expression $substitute
            $yaml = $yaml.Replace("{{$substitute}}", "$value")
          } else {
            $value = Invoke-Expression "`$config.attributes.$substitute" -ErrorAction Stop
            if (-not $regex.Match($value).Success) {
              $yaml = $yaml.Replace("{{$substitute}}", "$value")
            }
          }
        }
        if ($counter++ -ge 100) {
          throw "Circular reference detected for substitutions: $($regex.Matches($yaml) | Sort-Object -Property Value)"
        }
        $config = ConvertFrom-Yaml $yaml
        $yaml = ConvertTo-Yaml $config
      } while ($regex.Match($yaml).Success)

      return ConvertFrom-Yaml $yaml
  }
}
