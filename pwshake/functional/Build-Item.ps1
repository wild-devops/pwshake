function Build-Item {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [object]$item,

    [Parameter(Mandatory = $false)]
    [hashtable]$config = (Peek-Config)
  )
  process {
    $ErrorActionPreference = "Stop"
    "Build-Item:In:`$_:`n$(cty $_)" | f-log-dbg

    switch ($item) {
      {$null -eq $item} {
        return $null
      }
      {$item -is [string]} {
        return @{ name = $item; script = $item }
      }
      {($item -is [hashtable]) -and ($item.Keys.Count -eq 1)} {
        $item = $item | f-cli-tool
        $temlate_key = $item | f-template-key -add 'pwsh', 'powershell'
        "Build-Item:`$temlate_key`:$temlate_key" | f-log-dbg
        if ($null -eq $temlate_key) {
          # we have some cunny naming in item
          $key = "$($item.Keys)"
          $value = $item.$($key)
          "Build-Item:`$value:`n$(cty $value)" | f-log-dbg
          switch ($value) {
            {$null -eq $value} {
              # 'Some name':
              $item = @{name = $key; powershell = '$null' }
            }
            {$value -is [string]} {
              # 'Some name': payload
              $item = @{ name = $key; powershell = $value }
            }
            {$value -is [hashtable]} {
              # 'Some name':
              #   some: payload
              if ($value.Keys -notcontains 'name') {
                $item = Merge-Hashtables $value @{ name = $key }
              } else {
                $item = $value
              }
            }
          }
        }
      }
      {($item -is [hashtable])} {
        # 'Some name':
        # some: payload
        @() + $item.Keys | Where-Object { $_ -match '\s' } | ForEach-Object {
        $item.Remove($_)
          $item = Merge-Hashtables $item @{ name = $_ }
        }
      }
      default { throw "Unknown item type: $($item.GetType().Name)" }
    }

    if (!$item.name) {
      $item.name = "$(Coalesce $temlate_key, 'step')_$((++(Peek-Invocation).steps_count) | Write-Output)"
    }

    "Build-Item:Out:`$item:`n$($item | cty)" | f-log-dbg
    return $item
  }
}
