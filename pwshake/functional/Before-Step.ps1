function Before-Step {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  "Before-Step:In:$(${@context}.name): $(${@context} | f-ctj-c)" | f-log-dbg
  ${@context} | &${@next}
}
