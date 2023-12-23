function Build-Item {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [object]$item,

    [Parameter(Mandatory = $false)]
    [hashtable]$config = (Coalesce (Peek-Config), @{}),

    [Parameter(Mandatory = $false)]
    [Collections.ICollection]${reserved-keys} = (@('pwsh', 'powershell') + ${global:pwshake-context}.templates.Keys)
  )
  process {
    "Build-Item:In:`$_:`n$(cty $_)" | f-log-dbg

    if ($null -eq $item) {
      return $null
    }
    elseif ($item -is [string]) {
      $item = @{ name = $item; script = $item }
    }
    elseif ($item -isnot [hashtable]) {
      throw "Unknown item type: $($item.GetType().Name)"
    }

    $temlate_key = Compare-Object (@() + $item.Keys) (@() + ${reserved-keys}) `
      -PassThru -IncludeEqual -ExcludeDifferent # intersection
    "Build-Item:`$temlate_key`:$temlate_key" | f-log-dbg

    if ($item.pwsh) {
      $item.powershell = $item.pwsh
      $item.Remove('pwsh')
    }

    if (($item.Keys.Count -eq 1) -and ($null -eq $temlate_key)) {
      $key = "$($item.Keys)"
      $content = $item.$($key)
      "Build-Item:`$content:`n$($content | f-ctj)" | f-log-dbg
      if (${reserved-keys} -notcontains $key) {
        if (($null -eq $content) -or ('' -eq $content)) {
          # 'Some name':
          $item = @{name = $key }
        }
        elseif ($content -is [string]) {
          # 'Some name': payload
          $item.name = $key
        }
        elseif ($content -is [hashtable]) {
          # 'Some name':
          #   some: payload
          if ($content.Keys -notcontains 'name') {
            $item = Merge-Hashtables $content @{ name = $key }
          }
          else {
            $item = $content
          }
        }
      }
    }

    if (!$item.name) {
      $item.name = "$(Coalesce $temlate_key, 'step')_$((++(Peek-Invocation).steps_count) | Write-Output)"
    }

    "Build-Item:Out:`$item:`n$(cty $item)" | f-log-dbg
    return $item
  }
}
