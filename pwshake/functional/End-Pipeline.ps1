function End-Pipeline {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  param (
    [object]$context,
    [scriptblock]$next={}
  )
  "End-Pipeline:Out:$(Peek-Verbosity):`$context: $context" | f-log-dbg
  # "End-Pipeline:Out:$(Peek-Verbosity):`$context: $context" | f-tee-wh-m | f-log-dbg
}
