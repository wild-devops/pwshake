function Override-Attributes {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$config
  )
  process {
    $ErrorActionPreference = "Stop"

    foreach ($item in $config.attributes_overrides) {
      $type = $item
      "Override-Attributes:`n$(@{'$item'=$item;'$config.attributes.override_to'=$config.attributes.override_to} | ctj)" | f-log-dbg
      if ($item -is [hashtable]) {
        if ($item.Keys.Count -gt 1) {
          throw "Item of 'attributes_overrides:' can't contain $($item.Keys.Count) keys."
        }
        $type = "$($item.Keys)"
        $path = Build-Path -Path "$($item.$($type))"
      } elseif ($item -is [string]) {
        $path = Resolve-Path -Path "$($config.attributes.pwshake_path)\attributes_overrides\$item.yaml"
      } else {
        throw "Unknown type of 'attributes_overrides:' item: '$($item.GetType())'."
      }

      $override = $path | Build-FromYaml
      $config.attributes = Merge-Hashtables $config.attributes $override
      if ($type -eq $config.attributes.override_to) {
        "Override-Attributes:Break-On:`$type`: $type" | f-log-dbg
        break
      }
    }

    "Override-Attributes:Out:`$config`:`n$($config | cty)" | f-log-dbg
    return $config
  }
}
