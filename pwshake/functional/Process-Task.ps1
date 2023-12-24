function Process-Task {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  $task = ${@context}.Value
  "Process-Task $($task.name): $($task | f-ctj-c)" | f-log-dbg
  $invoke_step = @(
    'Before-Step'
    'Process-Step'
    'After-Step'
    ) | Build-Pipeline
    foreach ($step in $task.steps) {
    &$invoke_step $step
  }
  ${@context} | &${@next}
}
