function Override-Attributes {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$config
)    
  process {

    foreach ($type in $config.attributes_overrides) {
      $path = Resolve-Path -Path "$($config.attributes.pwshake_path)\attributes_overrides\$type.yaml"
      $override = $path | Normalize-Yaml
      $config.attributes = Merge-Hashtables $config.attributes $override
      if ($type -eq $config.attributes.override_to) {
        break
      }
    }

    return $config
  }
}
