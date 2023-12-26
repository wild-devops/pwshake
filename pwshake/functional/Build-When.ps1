function Build-When {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Position = 0, Mandatory = $false)]
    [object]$item
  )
  process {
    $when = "`$true"
    if (-not $item) {
      return $when
    }

    if ($item -is [Hashtable]) {
      if ($item.when) { $when = $item.when }
      elseif ($item.only) { $when = $item.only }
      elseif ($item.except) { $when = "-not ($($item.except))" }
      elseif ($item.skip_on) { $when = "-not ($($item.skip_on))" }
    }
    return $when
  }
}
