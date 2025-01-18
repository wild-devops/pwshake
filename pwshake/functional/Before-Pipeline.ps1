function Before-Pipeline {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  "Before-Pipeline:In: $(${@context} | f-ctj-c)" | f-log-dbg
  
  "PWSHAKE arguments:`n$(${global:actor-context}.arguments | f-cty)" | f-log-verb
  
  "PWSHAKE config:`n$(${global:actor-context}.config | f-cty)" | f-log-verb

  &${@next} ${@context}
}
