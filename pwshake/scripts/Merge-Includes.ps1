function Merge-Includes {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$config,

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$yamlPath = (Peek-Invocation).arguments.ConfigPath,

    [Parameter(Mandatory = $false)]
    [int]$depth = 0
  )
  process {
    if ($depth -gt ${global:pwshake-context}.options.max_depth) {
      throw "Circular reference detected for includes in: $yamlPath"
    }

    foreach ($path in $config.includes) {
      $config_path = Split-Path $yamlPath -Parent
      $include_path = Join-Path -Path $config_path -ChildPath $path
      if ((Get-Item $include_path).BaseName -eq 'attributes') {
        $attributes = $include_path | Build-FromYaml
        $config.attributes = Merge-Hashtables $config.attributes $attributes
      }
      else {
        $include = $include_path | Build-FromYaml | Build-Config | Merge-Includes -yamlPath $include_path -depth ($depth + 1)
        $config = Merge-Hashtables $config $include
      }
    }

    # to avoid templates misconfiguration in each loaded $config reload built-in templates first
    $templates = @{}
    foreach ($template in (Get-ChildItem -Path "$PSScriptRoot/../templates/*.yaml" -Recurse)) {
        $context = Build-FromYaml $template | ForEach-Object 'pwshake-context'
        $templates = Merge-Hashtables $templates (Coalesce $context.templates, $context.actions, @{})
    }
    ${global:pwshake-context}.templates = $templates

    $config.templates.GetEnumerator() | ForEach-Object {
      ${global:pwshake-context}.templates.$($_.Key) = $_.Value
    }

    $config.filters.GetEnumerator() | ForEach-Object {
      Invoke-Expression "filter script:$($_.Key) $($_.Value)"
    }

    return $config
  }
}
