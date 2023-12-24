function Before-Task {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  "Before-Task $(${@context}.name): $(${@context} | f-ctj-c)" | f-log-dbg
  $steps = @()
  foreach ($step in ${@context}.steps) {
    $item = @{
      name = "$($step.Keys)"
    }
    $step.$($item.name).GetEnumerator() | % {
      $item.$($_.Key) = $_.Value
    }
    $steps += $item
  }
  ${@context}.steps = $steps
  ${@context} | &${@next}
}
