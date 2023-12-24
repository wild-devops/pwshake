function Process-ErrorRecord {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  if (${@context}.Value -is [Management.Automation.ErrorRecord]) {
    ${@context}.Value = (${@context}.Value | f-error)
  }
  "@Process-ErrorRecord:In:`n$('${@context}.Value', '${@next}' | f-vars-cty)" | f-log-dbg
  &${@next} ${@context}
}
