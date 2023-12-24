function Process-Output {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([void])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}
  )
  "@Process-Output:In:`n$(@{'@context'=${@context}} | cty)" | f-log-dbg

  ## Build some pipeline
  $pipeline = @(
    'Process-ErrorRecord'
    'Log-Output'
  ) | Build-Pipeline


  "@Process-Output:Out:`$pipeline:$pipeline" | f-log-dbg
  &$pipeline ${@context}
}
