function Merge-Includes {
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  process {
    [hashtable]$config = ${@context}.config
    [string]$yamlPath = Coalesce ${@context}.yamlPath, ${global:actor-context}.arguments.ConfigPath
    [int]$depth = Coalesce ${@context}.depth, 0
    
    if ($depth -gt ${global:actor-context}.options.max_depth) {
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
        $include = $include_path | Build-FromYaml | Build-Config | % {@{config=$_;yamlPath=$include_path;depth=($depth+1)}} | Merge-Includes
        $config = Merge-Hashtables $include $config # set precedence current config over included one
      }
    }

    $config.templates.GetEnumerator() | ForEach-Object {
      # override context templates with config's ones
      ${global:actor-context}.templates.$($_.Key) = $_.Value
    }

    $config.filters.GetEnumerator() | ForEach-Object {
      Invoke-Expression "filter script:$($_.Key) $($_.Value)"
    }

    return &${@next}(@{config=$config})
  }
}
