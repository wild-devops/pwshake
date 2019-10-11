function Merge-Includes {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [hashtable]$config,

      [Parameter(Position = 1, Mandatory = $true)]
      [string]$yamlPath,

      [Parameter(Mandatory = $false)]
      [int]$depth = 0
  )    
    process {
      if ($depth -gt 100) {
        throw "Circular reference detected for includes in: $yamlPath"
      }
  
      foreach ($path in $config.includes) {
        $config_path = Split-Path -Path $yamlPath -Parent
        $include_path = Join-Path -Path $config_path -ChildPath $path
        if ((Get-Item $include_path).BaseName -eq 'attributes') {
          $attributes = Get-Content $include_path -Raw | ConvertFrom-Yaml
          $config.attributes = Merge-Hashtables $config.attributes $attributes
        } else {
          $include = Load-Config $include_path | Merge-Includes -yamlPath $include_path -depth ($depth + 1)
          $config = Merge-Hashtables $config $include
        }
      }
  
      return $config
    }
}