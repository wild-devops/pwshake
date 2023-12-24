function Process-Pipeline {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  "Process-Pipeline:In: $(${@context} | f-ctj-c)" | f-log-dbg

  $invoke_task = @(
    'Before-Task'
    'Process-Task'
    'After-Task'
    ) | Build-Pipeline
    foreach ($key in ${@context}.invoke_tasks) {
      &$invoke_task ${@context}.tasks.$($key)
  }
  ${@context} | &${@next}
}
