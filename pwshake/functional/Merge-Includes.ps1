function Merge-Includes {
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$config,

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$yamlPath = (Peek-Invocation).arguments.ConfigPath,

    [Parameter(Mandatory = $false)]
    [int]$depth = 0
  )
  process {
    if ($depth -gt (Peek-Options).max_depth) {
      throw "Circular reference detected for includes in: $yamlPath"
    }

    foreach ($path in $config.includes) {
      $config_path = Resolve-Path -Path $yamlPath | Split-Path -Parent
      $include_path = Join-Path -Path $config_path -ChildPath $path
      if ((Get-Item $include_path).BaseName -eq 'attributes') {
        $attributes = $include_path | Build-FromYaml
        $config.attributes = Merge-Hashtables $attributes $config.attributes # set precedence current config over included one
      }
      else {
        $include = $include_path | Build-FromYaml | Build-Config | Merge-Includes -yamlPath $include_path -depth ($depth + 1)
        $config = Merge-Hashtables $include $config # set precedence current config over included one
      }
    }

    $config.templates.GetEnumerator() | ForEach-Object {
      # override context templates with config's ones
      (Peek-Context).templates.$($_.Key) = $_.Value
    }

    $config.filters.GetEnumerator() | ForEach-Object {
      Invoke-Expression "filter script:$($_.Key) $($_.Value)"
    }

    return $config
  }
}
