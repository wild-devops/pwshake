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
  ${@context}.tasks = &{
    $tasks = @{}
    foreach ($key in ${@context}.tasks.Keys) {
      $tasks.$($key) = @{
        name  = $key
        steps = ${@context}.tasks.$($key)
      }
    }
    $tasks
  }
  ${@context} | &${@next}
}
